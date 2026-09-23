# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'puppet_x/gpno/backup_manifest'

describe PuppetX::Gpno::BackupManifest do
  let(:fixture_root)    { File.expand_path('../../../../fixtures/gpo_backups', __dir__) }
  let(:backup_dir)      { File.join(fixture_root, 'backup_mode') }
  let(:sysvol_dir)      { File.join(fixture_root, 'sysvol_mode') }
  let(:gpt_ini_path)    { File.join(sysvol_dir, 'GPT.INI') }
  let(:backup_expected) { JSON.parse(File.read(File.join(backup_dir, 'expected_ir.json'))) }
  let(:sysvol_expected) { JSON.parse(File.read(File.join(sysvol_dir, 'expected_ir.json'))) }

  describe '.parse (auto-detect)' do
    it 'auto-detects backup mode from a directory containing Backup.xml' do
      expect(described_class.parse(backup_dir)).to eq(backup_expected)
    end

    it 'auto-detects SYSVOL mode from a directory containing GPT.INI' do
      expect(described_class.parse(sysvol_dir)).to eq(sysvol_expected)
    end

    it 'auto-detects SYSVOL mode from a direct GPT.INI path' do
      expect(described_class.parse(gpt_ini_path)).to eq(sysvol_expected)
    end

    it 'auto-detects backup mode from a direct Backup.xml path' do
      backup_xml_path = File.join(backup_dir, 'Backup.xml')
      expect(described_class.parse(backup_xml_path)).to eq(backup_expected)
    end

    it 'raises ArgumentError for an unrecognized file path' do
      Dir.mktmpdir do |dir|
        unknown = File.join(dir, 'unknown.xml')
        File.write(unknown, '<xml/>')
        expect { described_class.parse(unknown) }.to raise_error(ArgumentError)
      end
    end

    it 'raises ArgumentError for a directory with neither Backup.xml nor GPT.INI' do
      Dir.mktmpdir do |dir|
        expect { described_class.parse(dir) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.parse_backup' do
    it 'returns IR matching expected_ir.json for the backup_mode fixture' do
      expect(described_class.parse_backup(backup_dir)).to eq(backup_expected)
    end

    it 'sets source to "backup"' do
      expect(described_class.parse_backup(backup_dir)['source']).to eq('backup')
    end

    it 'includes GPO id from Backup.xml' do
      result = described_class.parse_backup(backup_dir)
      expect(result['id']).to eq('{ABCD1234-5678-90AB-CDEF-012345678901}')
    end

    it 'includes display_name from Backup.xml' do
      result = described_class.parse_backup(backup_dir)
      expect(result['display_name']).to eq('Test Security Policy')
    end

    it 'includes link information from Backup.xml' do
      result = described_class.parse_backup(backup_dir)
      expect(result['links']).to be_an(Array)
      expect(result['links'].length).to eq(1)

      link = result['links'].first
      expect(link['som_id']).to eq('OU=Workstations,DC=test,DC=example,DC=com')
      expect(link['enabled']).to be(true)
      expect(link['no_override']).to be(false)
    end

    it 'includes domain and backup_time from bkupInfo.xml' do
      result = described_class.parse_backup(backup_dir)
      expect(result['domain']).to eq('test.example.com')
      expect(result['backup_time']).to eq('2024-01-15T10:30:00Z')
    end

    it 'sets wmi_filter_id to nil when the WMIFilterID element is empty' do
      expect(described_class.parse_backup(backup_dir)['wmi_filter_id']).to be_nil
    end

    it 'raises ArgumentError when Backup.xml is not found' do
      Dir.mktmpdir do |dir|
        expect { described_class.parse_backup(dir) }.to raise_error(ArgumentError, %r{Backup.xml not found})
      end
    end

    it 'still succeeds when bkupInfo.xml is absent' do
      Dir.mktmpdir do |dir|
        FileUtils.cp(File.join(backup_dir, 'Backup.xml'), dir)
        result = described_class.parse_backup(dir)
        expect(result['id']).to eq('{ABCD1234-5678-90AB-CDEF-012345678901}')
        expect(result['source']).to eq('backup')
        expect(result).not_to have_key('domain')
      end
    end
  end

  describe '.parse_sysvol' do
    it 'returns IR matching expected_ir.json for the sysvol_mode fixture' do
      expect(described_class.parse_sysvol(gpt_ini_path)).to eq(sysvol_expected)
    end

    it 'sets links to the sentinel string "unresolved"' do
      result = described_class.parse_sysvol(gpt_ini_path)
      expect(result['links']).to eq('unresolved')
    end

    it 'sets id to nil' do
      expect(described_class.parse_sysvol(gpt_ini_path)['id']).to be_nil
    end

    it 'sets source to "sysvol"' do
      expect(described_class.parse_sysvol(gpt_ini_path)['source']).to eq('sysvol')
    end

    it 'parses the version as an integer' do
      result = described_class.parse_sysvol(gpt_ini_path)
      expect(result['version']).to eq(524_288)
    end

    it 'parses the displayName from GPT.INI' do
      result = described_class.parse_sysvol(gpt_ini_path)
      expect(result['display_name']).to eq('TestPolicy')
    end

    it 'raises ArgumentError when GPT.INI is not found' do
      expect { described_class.parse_sysvol('/nonexistent/GPT.INI') }
        .to raise_error(ArgumentError, %r{GPT.INI not found})
    end

    it 'sets version to nil when Version key is absent from GPT.INI' do
      Dir.mktmpdir do |dir|
        gpt = File.join(dir, 'GPT.INI')
        File.write(gpt, "[General]\ndisplayName=NoVersion\n")
        result = described_class.parse_sysvol(gpt)
        expect(result['version']).to be_nil
        expect(result['display_name']).to eq('NoVersion')
      end
    end
  end
end
