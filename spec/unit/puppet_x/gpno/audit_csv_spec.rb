# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'puppet_x/gpno/audit_csv'

describe PuppetX::Gpno::AuditCsv do
  let(:fixture_dir) { File.expand_path('../../../../fixtures/gpo_backups/audit_csv', __dir__) }
  let(:csv_path)    { File.join(fixture_dir, 'audit.csv') }
  let(:expected_ir) { JSON.parse(File.read(File.join(fixture_dir, 'expected_ir.json'))) }

  describe '.parse' do
    it 'returns IR that matches expected_ir.json for the audit_csv fixture' do
      expect(described_class.parse(csv_path)).to eq(expected_ir)
    end

    it 'keys every entry by GUID, not by the localized subcategory name' do
      result = described_class.parse(csv_path)
      result['audit_policy'].each_key do |key|
        expect(key).to match(%r{\A\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\z})
      end
    end

    it 'preserves the localized subcategory name in each entry for reference' do
      result = described_class.parse(csv_path)
      expect(result['audit_policy']['{0CCE9210-69AE-11D9-BED3-505054503030}']['subcategory_name'])
        .to eq('Security State Change')
    end

    it 'sets scope to Machine' do
      expect(described_class.parse(csv_path)['scope']).to eq('Machine')
    end

    it 'sets provenance source to audit_csv' do
      expect(described_class.parse(csv_path)['provenance']['source']).to eq('audit_csv')
    end

    it 'represents empty exclusion_setting as nil' do
      result = described_class.parse(csv_path)
      result['audit_policy'].each_value do |entry|
        expect(entry['exclusion_setting']).to be_nil
      end
    end
  end

  describe '.parse_string' do
    it 'parses valid CSV content and returns an IR hash' do
      content = <<~CSV
        Machine Name,Policy Target,Subcategory,Subcategory GUID,Inclusion Setting,Exclusion Setting
        ,System,Security State Change,{0CCE9210-69AE-11D9-BED3-505054503030},Success and Failure,
      CSV
      result = described_class.parse_string(content)
      expect(result['audit_policy']).to have_key('{0CCE9210-69AE-11D9-BED3-505054503030}')
      expect(result['audit_policy']['{0CCE9210-69AE-11D9-BED3-505054503030}']['inclusion_setting'])
        .to eq('Success and Failure')
    end

    it 'raises ArgumentError when the Subcategory GUID column is absent' do
      content = <<~CSV
        Machine Name,Policy Target,Subcategory,Inclusion Setting,Exclusion Setting
        ,System,Security State Change,Success and Failure,
      CSV
      expect { described_class.parse_string(content) }
        .to raise_error(ArgumentError, %r{Subcategory GUID})
    end

    it 'raises ArgumentError when a row has an empty GUID value' do
      content = <<~CSV
        Machine Name,Policy Target,Subcategory,Subcategory GUID,Inclusion Setting,Exclusion Setting
        ,System,Security State Change,,Success and Failure,
      CSV
      expect { described_class.parse_string(content) }
        .to raise_error(ArgumentError, %r{missing or empty})
    end

    it 'raises ArgumentError when a row has a nil GUID value' do
      content = "Machine Name,Policy Target,Subcategory,Subcategory GUID,Inclusion Setting,Exclusion Setting\n" \
                ",System,Security State Change,,Success and Failure,\n"
      expect { described_class.parse_string(content) }
        .to raise_error(ArgumentError)
    end

    it 'stores a non-empty exclusion_setting value' do
      content = <<~CSV
        Machine Name,Policy Target,Subcategory,Subcategory GUID,Inclusion Setting,Exclusion Setting
        ,System,Security State Change,{0CCE9210-69AE-11D9-BED3-505054503030},Success,Failure
      CSV
      result = described_class.parse_string(content)
      expect(result['audit_policy']['{0CCE9210-69AE-11D9-BED3-505054503030}']['exclusion_setting'])
        .to eq('Failure')
    end
  end
end
