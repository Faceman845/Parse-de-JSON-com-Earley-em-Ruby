# Módulo que expõe as regras da gramática livre de contexto (JSON + expressão)

module Gramatica
  REGRAS = {
    'S'            => [['OBJETO']],
    'OBJETO'       => [['CHAVE_ABRE','PARES','CHAVE_FECHA']],
    'PARES'        => [['PAR'], ['PAR','VIRGULA','PARES']],
    'PAR'          => [['STRING','DOIS_PONTOS','VALOR']],
    'VALOR'        => [
      ['STRING'], ['NUMERO'], ['BOOLEANO'], ['NULO'],
      ['OBJETO'], ['ARRAY'], ['EXP']
    ],
    'ARRAY'        => [['COLCHETE_ABRE','ELEMENTOS','COLCHETE_FECHA']],
    'ELEMENTOS'    => [['VALOR'], ['VALOR','VIRGULA','ELEMENTOS']],
    'EXP'          => [['EXPR_CALCULO']],  # expressão aritmética como token único
  }
end