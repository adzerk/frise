require 'frise/parser'

include Frise

RSpec.describe Parser do
  it 'should parse a YAML file without substitutions' do
    conf = Parser.parse(fixture_path('simple.yml'))
    expect(conf).to eq('str' => 'abc', 'int' => 4, 'bool' => true)
  end

  it 'parse the config with Liquid if a symbol table is passed' do
    conf1 = Parser.parse(fixture_path('simple_liquid.yml'), 'var1' => 'REPLACED', 'var2' => 1)
    expect(conf1).to eq('str' => 'replaced', 'int' => 1, 'bool' => true)

    conf2 = Parser.parse(fixture_path('simple_liquid.yml'), 'var1' => 'Yey!', 'var2' => 10)
    expect(conf2).to eq('str' => 'yey!', 'int' => 10, 'bool' => false)
  end
end
