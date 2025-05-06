# Implementação do algoritmo de Earley com avaliação semântica (sem debug)

require_relative 'gramatica'

# Estado do algoritmo Earley
class Estado
  attr_reader :simbolo, :producao, :posicao_ponto, :inicio, :valor

  def initialize(simbolo, producao, posicao_ponto, inicio, valor = nil)
    @simbolo = simbolo
    @producao = producao
    @posicao_ponto = posicao_ponto
    @inicio = inicio
    @valor = valor
  end

  # Símbolo após o ponto
  def proximo_simbolo
    producao[posicao_ponto]
  end

  # Verifica se completou a produção
  def completo?
    posicao_ponto >= producao.size
  end

  # Avança o ponto, opcionalmente definindo valor semântico
  def avancar(novo_valor = nil)
    Estado.new(simbolo, producao, posicao_ponto + 1, inicio, novo_valor)
  end

  # Igualdade considera nt, prod, dot, start
  def ==(outro)
    simbolo == outro.simbolo && 
    producao == outro.producao && 
    posicao_ponto == outro.posicao_ponto && 
    inicio == outro.inicio
  end
end

# Parser Earley sem debug
class ParserEarley
  include Gramatica

  def initialize(tokens)
    @tokens = tokens
    @colunas = Array.new(tokens.size + 1) { [] }
  end

  # Executa parsing e retorna valor semântico do objeto raiz
  def analisar
    semear_coluna_inicial
    (0..@tokens.size).each do |i|
      j = 0
      while j < @colunas[i].size
        estado = @colunas[i][j]
        if estado.completo?
          completar(estado, i)
        else
          simbolo = estado.proximo_simbolo
          terminal?(simbolo) ? escanear(estado, i) : prever(estado, i)
        end
        j += 1
      end
    end
    # Busca estado final S e retorna seu valor
    final = @colunas.last.find { |e| e.simbolo == 'S' && e.inicio == 0 && e.completo? }
    final ? final.valor : nil
  end

  private

  # Seed: adiciona S → • OBJETO
  def semear_coluna_inicial
    REGRAS['S'].each { |producao| @colunas[0] << Estado.new('S', producao, 0, 0) }
  end

  # Verifica se símbolo é terminal
  def terminal?(simbolo)
    !REGRAS.key?(simbolo)
  end

  # Predict: expande não-terminal
  def prever(estado, coluna)
    nt = estado.proximo_simbolo
    REGRAS[nt].each { |producao|
      novo_estado = Estado.new(nt, producao, 0, coluna)
      @colunas[coluna] << novo_estado unless @colunas[coluna].include?(novo_estado)
    }
  end

  # Scan: consome token terminal e avança coluna
  def escanear(estado, coluna)
    token = @tokens[coluna]
    if token && token.tipo.to_s == estado.proximo_simbolo.to_s
      # tokens de valor carregam valor; tokens estruturais mantêm estado.valor
      v = [:STRING, :NUMERO, :BOOLEANO, :NULO, :EXPR_CALCULO].include?(token.tipo) ? token.valor : estado.valor
      novo_estado = estado.avancar(v)
      @colunas[coluna + 1] << novo_estado unless @colunas[coluna + 1].include?(novo_estado)
    end
  end

  # Complete: avança estados que aguardavam o não-terminal concluído
  def completar(estado, coluna)
    @colunas[estado.inicio].each do |anterior|
      next if anterior.completo? || anterior.proximo_simbolo != estado.simbolo
      v = semantica(anterior, estado)
      novo_estado = anterior.avancar(v)
      @colunas[coluna] << novo_estado unless @colunas[coluna].include?(novo_estado)
    end
  end

  # Ação semântica: combina valores e avalia expressões
  def semantica(anterior, completo)
    case anterior.simbolo
    when 'PAR'
      chave = @tokens[anterior.inicio].valor
      { chave => completo.valor }

    when 'PARES'
      (anterior.valor || {}).merge(completo.valor)

    when 'OBJETO'
      completo.valor

    when 'ELEMENTOS'
      anterior.valor.is_a?(Array) ? anterior.valor + [completo.valor] : [completo.valor]

    when 'ARRAY'
      anterior.valor || []

    when 'S'
      completo.valor

    when 'VALOR'
      if anterior.producao == ['EXP']
        expr = completo.valor
        begin
          eval(expr.gsub('^', '**'))
        rescue SyntaxError, StandardError # Captura ambos os tipos de erro
          "#{expr} !(conta não aceita)!"
        end
      else
        completo.valor
      end
  
    when 'EXP'
      expr = completo.valor
      begin
        eval(expr.gsub('^', '**'))
      rescue SyntaxError, StandardError # Captura ambos os tipos de erro
        "#{expr} !(conta não aceita)!"
      end

    else
      completo.valor
    end
  end
end