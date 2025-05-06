# Script principal
require_relative 'analisador_lexico'
require_relative 'parser'

# Lê arquivo JSON, tokeniza, faz parsing e imprime estrutura
def main(file)
  txt    = File.read(file)
  lex    = AnalisadorLexico.new(txt)
  tokens = lex.tokenizar
  puts "Tokens Gerados:"
  tokens.each{|t| puts "  #{t}"}

  ast = ParserEarley.new(tokens).analisar
  puts "\nÁrvore (hash/array):"
  pp ast
rescue => e
  puts "Erro no parsing: #{e.message}"
end

main(ARGV[0]||'exemplo.json')