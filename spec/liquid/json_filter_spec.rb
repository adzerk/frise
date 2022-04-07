# frozen_string_literal: true

require 'liquid/liquid'

RSpec.describe JsonFilter do
  it 'should convert a string to JSON' do
    res = parse('{{ foo | json }}', { 'foo' => 'bar' })
    expect(res).to eq('"bar"')
  end

  it 'should convert a number to JSON' do
    res = parse('{{ foo | json }}', { 'foo' => 2 })
    expect(res).to eq('2')
  end

  it 'should convert a numeric array to JSON' do
    res = parse('{{ foo | json }}', { 'foo' => [1, 2, 3] })
    expect(res).to eq('[1,2,3]')
  end

  it 'should convert a string array to JSON' do
    res = parse('{{ foo | json }}', { 'foo' => %w[a b c] })
    expect(res).to eq('["a","b","c"]')
  end

  it 'should convert a object array to JSON' do
    res = parse('{{ foo | json }}', { 'foo' => [{ a: 'a', b: 1 }] })
    expect(res).to eq('[{"a":"a","b":1}]')
  end

  it 'should convert a complex object to JSON' do
    res = parse('{{ foo | json }}', { 'foo' => {
                  'foo' => 'bar',
                  'baz' => 2,
                  'nested' => {
                    'foo' => [1, 2, 3],
                    'baz' => %w[a b c]
                  }
                } })
    expect(res).to eq('{"foo":"bar","baz":2,"nested":{"foo":[1,2,3],"baz":["a","b","c"]}}')
  end

  it 'should convert a nil to JSON' do
    res = parse('{{ foo | json }}', { 'foo' => nil })
    expect(res).to eq('null')
  end

  it 'should convert a undefined variable to JSON' do
    res = parse('{{ foo | json }}', {})
    expect(res).to eq('null')
  end

  def parse(content, symbol_table)
    template = Liquid::Template.parse(content, error_mode: :strict)
    template.render!(symbol_table, { strict_filters: true })
  end
end
