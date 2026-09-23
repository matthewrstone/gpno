# frozen_string_literal: true

require 'rexml/document'

module PuppetX
  module Gpno
    # Parser for GPO backup-metadata files.
    #
    # Supports two source paths:
    #
    # **Backup mode** (produced by +Backup-GPO+):
    #   A directory containing +Backup.xml+ and, optionally, +bkupInfo.xml+.
    #   Returns a full IR including GPO identity, domain, linked OUs, and
    #   backup timestamp.
    #
    # **SYSVOL mode** (read directly from the SYSVOL share):
    #   A +GPT.INI+ file path, or a directory containing +GPT.INI+.
    #   Link metadata is not available in GPT.INI — the IR marks
    #   +links: "unresolved"+ as an explicit signal that the LDAP link-walker
    #   (WS4, M3) must run before link data is available.
    class BackupManifest
      # Auto-detect mode from path and delegate to the appropriate parser.
      #
      # @param path [String] path to a backup directory (containing Backup.xml),
      #   a SYSVOL GPO directory (containing GPT.INI), or a GPT.INI file
      # @return [Hash] IR hash (string keys)
      # @raise [ArgumentError] if mode cannot be determined or required files are missing
      def self.parse(path)
        if File.directory?(path)
          backup_xml = File.join(path, 'Backup.xml')
          gpt_ini    = File.join(path, 'GPT.INI')
          if File.exist?(backup_xml)
            parse_backup(path)
          elsif File.exist?(gpt_ini)
            parse_sysvol(gpt_ini)
          else
            raise ArgumentError,
                  "Cannot determine backup mode: no Backup.xml or GPT.INI found in #{path}"
          end
        elsif File.basename(path).casecmp('Backup.xml').zero?
          parse_backup(File.dirname(path))
        elsif File.basename(path).casecmp('GPT.INI').zero?
          parse_sysvol(path)
        else
          raise ArgumentError,
                "Cannot determine backup mode for path: #{path}. " \
                'Provide a directory, a Backup.xml file, or a GPT.INI file.'
        end
      end

      # Parse a GPO backup directory (Backup.xml + optional bkupInfo.xml).
      #
      # @param dir [String] path to directory containing Backup.xml
      # @return [Hash] IR hash with full GPO identity and link information
      # @raise [ArgumentError] if Backup.xml is not found
      def self.parse_backup(dir)
        backup_xml    = File.join(dir, 'Backup.xml')
        bkup_info_xml = File.join(dir, 'bkupInfo.xml')

        raise ArgumentError, "Backup.xml not found in #{dir}" unless File.exist?(backup_xml)

        ir = parse_backup_xml(backup_xml)

        if File.exist?(bkup_info_xml)
          ir.merge!(parse_bkup_info_xml(bkup_info_xml))
        end

        ir['source'] = 'backup'
        ir
      end

      # Parse a GPT.INI file from SYSVOL mode.
      #
      # Link information is not available in GPT.INI; the returned IR carries
      # +links: "unresolved"+ to signal this explicitly.
      #
      # @param gpt_ini_path [String] path to GPT.INI
      # @return [Hash] IR hash with links set to the sentinel string "unresolved"
      # @raise [ArgumentError] if GPT.INI is not found
      def self.parse_sysvol(gpt_ini_path)
        raise ArgumentError, "GPT.INI not found: #{gpt_ini_path}" unless File.exist?(gpt_ini_path)

        data = parse_gpt_ini(gpt_ini_path)
        {
          'id'           => nil,
          'display_name' => data['displayName'],
          'version'      => data['version'],
          'links'        => 'unresolved',
          'source'       => 'sysvol',
        }
      end

      # @api private
      def self.parse_backup_xml(path)
        doc      = REXML::Document.new(File.read(path, encoding: 'UTF-8'))
        gpo_data = doc.root&.elements&.[]('GroupPolicyObject/GroupPolicyData')

        raise ArgumentError, "Invalid Backup.xml: missing GroupPolicyObject/GroupPolicyData in #{path}" if gpo_data.nil?

        wmi_filter_id = xml_text(gpo_data, 'WMIFilterID')
        wmi_filter_id = nil if wmi_filter_id&.empty?

        links = []
        gpo_data.elements.each('Links/Link') do |link|
          enabled_str     = xml_text(link, 'Enabled')
          no_override_str = xml_text(link, 'NoOverride')
          links << {
            'som_id'      => xml_text(link, 'SOMId'),
            'som_path'    => xml_text(link, 'SOMPath'),
            'enabled'     => parse_bool(enabled_str, default: true),
            'no_override' => parse_bool(no_override_str, default: false),
            'domain_name' => xml_text(link, 'DomainName'),
          }
        end

        {
          'id'            => xml_text(gpo_data, 'ID'),
          'display_name'  => xml_text(gpo_data, 'DisplayName'),
          'description'   => xml_text(gpo_data, 'Description') || '',
          'wmi_filter_id' => wmi_filter_id,
          'links'         => links,
        }
      end
      private_class_method :parse_backup_xml

      # @api private
      def self.parse_bkup_info_xml(path)
        doc  = REXML::Document.new(File.read(path, encoding: 'UTF-8'))
        root = doc.root

        {
          'domain'      => xml_text(root, 'GPODomain'),
          'domain_guid' => xml_text(root, 'GPODomainGuid'),
          'backup_time' => xml_text(root, 'BackupTime'),
        }
      end
      private_class_method :parse_bkup_info_xml

      # Parse a GPT.INI file, handling both UTF-8 and UTF-16LE (with BOM).
      # @api private
      def self.parse_gpt_ini(path)
        raw = File.binread(path)

        # Detect UTF-16LE BOM (FF FE) or UTF-16BE BOM (FE FF)
        content = if raw.start_with?("\xFF\xFE".b)
                    raw.force_encoding('UTF-16LE').encode('UTF-8')
                  elsif raw.start_with?("\xFE\xFF".b)
                    raw.force_encoding('UTF-16BE').encode('UTF-8')
                  else
                    raw.force_encoding('UTF-8')
                  end

        ini = {}
        content.each_line do |line|
          line = line.strip
          next if line.empty? || line.start_with?('[')
          key, value = line.split('=', 2)
          next unless key && value
          ini[key.strip] = value.strip
        end

        {
          'displayName' => ini['displayName'],
          'version'     => ini['Version']&.to_i,
        }
      end
      private_class_method :parse_gpt_ini

      # @api private
      def self.xml_text(element, name)
        el = element.elements[name]
        return nil if el.nil?
        el.text&.strip
      end
      private_class_method :xml_text

      # @api private
      def self.parse_bool(str, default:)
        return default if str.nil? || str.empty?
        str.casecmp('true').zero?
      end
      private_class_method :parse_bool
    end
  end
end
