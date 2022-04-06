# frozen_string_literal: true

require 'frise/parser'

include Frise

RSpec.describe Parser do
  it 'should parse a plain YAML file' do
    conf = Parser.parse(fixture_path('simple.yml'))
    expect(conf).to eq('str' => 'abc', 'int' => 4, 'bool' => true)
  end

  it 'parse a file as a Liquid template if a symbol table is passed' do
    conf1 = Parser.parse(fixture_path('simple_liquid.yml'),
                         'var1' => 'REPLACED',
                         'var2' => 1,
                         'var3' => {
                           'foo' => 'bar',
                           'baz' => 2,
                           'nested' => {
                             'foo' => [1, 2, 3],
                             'baz' => %w[a b c]
                           }
                         })
    expect(conf1).to eq('str' => 'replaced',
                        'int' => 1,
                        'bool' => true,
                        'json' => {
                          'foo' => 'bar',
                          'baz' => 2,
                          'nested' => {
                            'foo' => [1, 2, 3],
                            'baz' => %w[a b c]
                          }
                        },
                        'json_string' => '{"foo":"bar","baz":2,"nested":{"foo":[1,2,3],"baz":["a","b","c"]}}')

    conf2 = Parser.parse(fixture_path('simple_liquid.yml'),
                         'var1' => 'Yey!',
                         'var2' => 10,
                         'var3' => [{
                           'foo' => 1,
                           'bar' => 'a'
                         }, {
                           'foo' => 2,
                           'bar' => 'b'
                         }])
    expect(conf2).to eq('str' => 'yey!',
                        'int' => 10,
                        'bool' => false,
                        'json' => [{
                          'foo' => 1,
                          'bar' => 'a'
                        }, {
                          'foo' => 2,
                          'bar' => 'b'
                        }],
                        'json_string' => '[{"foo":1,"bar":"a"},{"foo":2,"bar":"b"}]')
  end
end
