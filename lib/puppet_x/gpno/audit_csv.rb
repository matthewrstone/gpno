# frozen_string_literal: true

require 'csv'

module PuppetX
  module Gpno
    # Parser for Windows Advanced Audit Policy CSV files.
    #
    # Accepts the output format produced by +auditpol /get /r+ and by
    # +Backup-GPO+ (stored under
    # DomainSysvol/GPO/Machine/Microsoft/Windows NT/Audit/audit.csv).
    #
    # Rules (see AGENTS.md §6):
    # * Subcategories are keyed exclusively by GUID — never by the localized name.
    # * The "Subcategory GUID" column MUST be present; rows with a missing GUID
    #   raise ArgumentError so that callers can never silently process bad data.
    # * The localized "Subcategory" name is preserved in the IR for human
    #   readability but is never used as a key.
    class AuditCsv
      GUID_HEADER      = 'Subcategory GUID'
      NAME_HEADER      = 'Subcategory'
      INCLUSION_HEADER = 'Inclusion Setting'
      EXCLUSION_HEADER = 'Exclusion Setting'

      # Parse an audit.csv file and return an IR hash.
      #
      # @param path [String] absolute path to the audit.csv file
      # @return [Hash] IR hash (string keys)
      # @raise [ArgumentError] if the GUID column is absent or any row has a
      #   missing GUID value
      def self.parse(path)
        content = File.read(path, encoding: 'UTF-8')
        parse_string(content)
      end

      # Parse CSV content from a string and return an IR hash.
      #
      # @param content [String] raw CSV text
      # @return [Hash] IR hash (string keys)
      # @raise [ArgumentError] if the GUID column is absent or any row has a
      #   missing GUID value
      def self.parse_string(content)
        table = CSV.parse(content.strip, headers: true)

        unless table.headers.include?(GUID_HEADER)
          raise ArgumentError,
                "audit.csv is missing the required '#{GUID_HEADER}' column. " \
                "Only auditpol /get /r format (with GUID column) is accepted; " \
                "never key by localized subcategory name."
        end

        entries = {}

        table.each_with_index do |row, idx|
          guid = row[GUID_HEADER]&.strip
          if guid.nil? || guid.empty?
            name = row[NAME_HEADER]&.strip || '<unknown>'
            raise ArgumentError,
                  "Row #{idx + 2} (subcategory '#{name}') has a missing or empty " \
                  "'#{GUID_HEADER}' value. All audit subcategory rows must have a " \
                  "valid GUID."
          end

          exclusion = row[EXCLUSION_HEADER]&.strip
          exclusion = nil if exclusion&.empty?

          entries[guid] = {
            'subcategory_name'  => row[NAME_HEADER]&.strip,
            'inclusion_setting' => row[INCLUSION_HEADER]&.strip,
            'exclusion_setting' => exclusion,
          }
        end

        {
          'audit_policy' => entries,
          'scope'        => 'Machine',
          'provenance'   => { 'source' => 'audit_csv' },
        }
      end
    end
  end
end
