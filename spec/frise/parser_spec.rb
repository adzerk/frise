# frozen_string_literal: true

require 'frise/parser'

include Frise

RSpec.describe Parser do
  it 'should parse a plain YAML file' do
    conf = Parser.parse(fixture_path('simple.yml'))
    expect(conf).to eq('str' => 'abc', 'int' => 4, 'bool' => true)
  end

  it 'should raise an exception if parsing invalid liquid template' do
    expect { Parser.parse(fixture_path('invalid_liquid_1.yml'), { a: 1 }) }.to raise_exception(Liquid::SyntaxError)
    expect { Parser.parse(fixture_path('invalid_liquid_2.yml'), { a: 1 }) }.to raise_exception(Liquid::UndefinedFilter)

    # FIXME: If the symbol_table is empty we don't render the template.
    #        Not sure if we want this behaviour in the long run
    expect { Parser.parse(fixture_path('invalid_liquid_2.yml')) }.not_to raise_exception
  end

  it 'parse a file as a Liquid template if a symbol table is passed' do
    conf1 = Parser.parse(fixture_path('simple_liquid.yml'), 'var1' => 'REPLACED', 'var2' => 1)
    expect(conf1).to eq('str' => 'replaced', 'int' => 1, 'bool' => true)

    conf2 = Parser.parse(fixture_path('simple_liquid.yml'), 'var1' => 'Yey!', 'var2' => 10)
    expect(conf2).to eq('str' => 'yey!', 'int' => 10, 'bool' => false)
  end
end
