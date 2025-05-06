# Analisador lexical para JSON estendido com expressões aritméticas

class Token
  # Representa um token extraído do texto de entrada
  # - tipo: símbolo que indica a categoria (e.g., :STRING, :NUMERO, :CHAVE_ABRE)
  # - valor: conteúdo real para tokens de valor (strings, números, booleanos)
  attr_reader :tipo, :valor

  def initialize(tipo, valor = nil)
    @tipo  = tipo
    @valor = valor
  end
  
  # Para facilitar o debug, imprime "TIPO(valor)" ou somente "TIPO"
  def to_s
    valor ? "#{tipo}(#{valor})" : tipo.to_s
  end
end



class AnalisadorLexico
  OPERADORES = ['+', '-', '*', '/', '^']

  def initialize(entrada)
    @entrada = entrada   # string completa do JSON
    @pos     = 0         # índice de leitura atual
    @tokens  = []        # lista de Token a ser retornada
  end

  # Varre a entrada e popula @tokens
  def tokenizar
    while (caractere = caractere_atual)
      case caractere
      when /\s/        # ignora espaços, quebras de linha...
        avancar
      when '{'
        adicionar_token(:CHAVE_ABRE)
      when '}'
        adicionar_token(:CHAVE_FECHA)
      when '['
        adicionar_token(:COLCHETE_ABRE)
      when ']'
        adicionar_token(:COLCHETE_FECHA)
      when ':'
        adicionar_token(:DOIS_PONTOS)
      when ','
        adicionar_token(:VIRGULA)
      when '"'
        ler_string    # string JSON
      when '$'
        ler_expressao # expressão aritmética delimitada
      when /[0-9\-]/
        ler_numero    # número (int ou float) ou sinal
      else
        if palavra = verificar_palavra_reservada
          # true, false, null
          adicionar_token(palavra[:tipo], palavra[:valor], palavra[:tamanho])
        else
          raise "Caractere inválido: #{caractere.inspect}"
        end
      end
    end
    @tokens
  end

  private

  # Retorna o caractere na posição @pos
  def caractere_atual
    @entrada[@pos]
  end

  # Avança a posição em n caracteres (default 1)
  def avancar(n = 1)
    @pos += n
  end

  # Empurra um token e avança o ponteiro
  def adicionar_token(tipo, valor = nil, tamanho = 1)
    @tokens << Token.new(tipo, valor)
    avancar(tamanho)
  end

  # Verifica palavras reservadas: true, false, null
  def verificar_palavra_reservada
    if proximos_caracteres(4) == 'true'
      { tipo: :BOOLEANO, valor: true, tamanho: 4 }
    elsif proximos_caracteres(5) == 'false'
      { tipo: :BOOLEANO, valor: false, tamanho: 5 }
    elsif proximos_caracteres(4) == 'null'
      { tipo: :NULO, valor: nil, tamanho: 4 }
    end
  end

  # Lê string JSON entre aspas, consumindo o delimitador
  def ler_string
    avancar # consome '"'
    s = ''
    while caractere_atual && caractere_atual != '"'
      s << caractere_atual
      avancar
    end
    raise 'String não fechada' unless caractere_atual == '"'
    avancar # consome '"'
    adicionar_token(:STRING, s, 0)
  end

  # Lê número, incluindo opcional parte decimal
  def ler_numero
    s = ''
    # sinal negativo
    if caractere_atual == '-'
      s << '-'
      avancar
    end
    # parte inteira
    while caractere_atual =~ /[0-9]/
      s << caractere_atual; avancar
    end
    # parte decimal opcional
    if caractere_atual == '.'
      s << '.'; avancar
      while caractere_atual =~ /[0-9]/
        s << caractere_atual; avancar
      end
    end
    # converte para Integer ou Float
    val = s.include?('.') ? s.to_f : s.to_i
    adicionar_token(:NUMERO, val, 0)
  end

  # Lê expressão aritmética entre $...$
  def ler_expressao
    avancar # consome '$'
    expr = ''
    while caractere_atual && caractere_atual != '$'
      expr << caractere_atual
      avancar
    end
    # Modificação: aceita expressões não fechadas
    if caractere_atual == '$'
      avancar
    end
    adicionar_token(:EXPR_CALCULO, expr.strip, 0)
  end

  # Retorna substring de comprimento len a partir de @pos
  def proximos_caracteres(len)
    @entrada[@pos, len]
  end
end