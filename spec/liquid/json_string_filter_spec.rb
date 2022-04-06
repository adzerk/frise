# frozen_string_literal: true

require 'liquid/liquid'

RSpec.describe JsonStringFilter do
  it 'should convert a string to a JSON string' do
    res = parse('{{ foo | json_string }}', { 'foo' => 'bar' })
    expect(res).to eq('\"bar\"')
  end

  it 'should convert a number to a JSON string' do
    res = parse('{{ foo | json_string }}', { 'foo' => 2 })
    expect(res).to eq('2')
  end

  it 'should convert a numeric array to a JSON string' do
    res = parse('{{ foo | json_string }}', { 'foo' => [1, 2, 3] })
    expect(res).to eq('[1,2,3]')
  end

  it 'should convert a string array to a JSON string' do
    res = parse('{{ foo | json_string }}', { 'foo' => %w[a b c] })
    expect(res).to eq('[\"a\",\"b\",\"c\"]')
  end

  it 'should convert a object array to a JSON string' do
    res = parse('{{ foo | json_string }}', { 'foo' => [{ a: 'a', b: 1 }] })
    expect(res).to eq('[{\"a\":\"a\",\"b\":1}]')
  end

  it 'should convert a complex object to a JSON string' do
    res = parse('{{ foo | json_string }}', { 'foo' => {
                  'foo' => 'bar',
                  'baz' => 2,
                  'nested' => {
                    'foo' => [1, 2, 3],
                    'baz' => %w[a b c]
                  }
                } })
    expect(res).to eq('{\"foo\":\"bar\",\"baz\":2,\"nested\":{\"foo\":[1,2,3],\"baz\":[\"a\",\"b\",\"c\"]}}')
  end

  it 'should convert a nil to a JSON string' do
    res = parse('{{ foo | json_string }}', { 'foo' => nil })
    expect(res).to eq('null')
  end

  it 'should convert a undefined variable to a JSON string' do
    res = parse('{{ foo | json_string }}', {})
    expect(res).to eq('null')
  end

  def parse(content, symbol_table)
    template = Liquid::Template.parse(content, error_mode: :strict)
    template.render!(symbol_table, { strict_filters: true })
  end
end
