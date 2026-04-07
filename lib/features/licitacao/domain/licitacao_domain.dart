// Domain constants for the Licitação module (Fase 5).
// Source: AUDESP API licitacao-schema-v4.json

/// Recurso BID / tri-state genérico (1=Sim, 2=Não, 3=Não se aplica).
const kTriState = <int, String>{
  1: '1 – Sim',
  2: '2 – Não',
  3: '3 – Não se aplica',
};

/// `recursoBID` — indica se há recursos do BID envolvidos.
const kRecursoBID = <int, String>{
  1: '1 – Sim',
  2: '2 – Não',
  3: '3 – Não informado',
};

/// `tipoNatureza` — natureza do objeto licitado.
const kTipoNatureza = <int, String>{
  1: '1 – Compras e Serviços',
  2: '2 – Obras',
  3: '3 – Serviços de Engenharia',
  4: '4 – Serviço de Saúde',
  5: '5 – Locação de Imóveis',
  6: '6 – Concessões e Permissões',
  7: '7 – Alienação de Bens',
  8: '8 – Outros',
};

/// `fonteRecursosContratacao` — fontes de recurso (multi-select).
const kFonteRecurso = <int, String>{
  1: '1 – Tesouro Municipal',
  2: '2 – Transferências correntes do Estado',
  3: '3 – Transferências correntes da União',
  4: '4 – Operações de crédito internas',
  5: '5 – Operações de crédito externas',
  6: '6 – Alienação de bens',
  7: '7 – Outras receitas',
  8: '8 – Recursos do FUNDEB',
  91: '91 – Convênio Estadual',
  92: '92 – Convênio Federal',
  93: '93 – Contrato de repasse',
  94: '94 – Termo de parceria',
  95: '95 – FNAS',
  96: '96 – FMAS',
  97: '97 – BID',
  98: '98 – BIRD',
};

/// `tipoOrcamento` — tipo do orçamento do item.
const kTipoOrcamento = <int, String>{
  0: '0 – Não informado',
  1: '1 – Sigiloso',
  2: '2 – Estimado',
  3: '3 – Fixado',
};

/// `situacaoCompraItemId` — situação do item de compra.
const kSituacaoCompraItem = <int, String>{
  1: '1 – Aberta',
  2: '2 – Adjudicada',
  3: '3 – Deserta',
  4: '4 – Fracassada',
  5: '5 – Cancelada',
};

/// `tipoProposta` — tipo de proposta do item.
const kTipoProposta = <int, String>{
  1: '1 – Por item',
  2: '2 – Global',
  3: '3 – Por lote',
};

/// `tipoValor` — tipo de valor do item.
const kTipoValor = <String, String>{
  'M': 'M – Médio',
  'U': 'U – Unitário',
  'G': 'G – Global',
};

/// `tipoPessoaId` — tipo de pessoa do licitante.
const kTipoPessoa = <String, String>{
  'PJ': 'PJ – Pessoa Jurídica',
  'PF': 'PF – Pessoa Física',
  'PE': 'PE – Pessoa Estrangeira',
};

/// `declaracaoMEouEPP` — declaração de ME ou EPP.
const kDeclaracaoMEouEPP = <int, String>{
  1: '1 – Declara ser ME ou EPP',
  2: '2 – Não declara',
  3: '3 – Não se aplica',
};

/// `resultadoHabilitacao` — resultado da habilitação do licitante.
const kResultadoHabilitacao = <int, String>{
  1: '1 – Habilitado',
  2: '2 – Inabilitado',
  3: '3 – Pendente',
  4: '4 – Desclassificado',
  5: '5 – Não analisado',
  6: '6 – Vencedor',
  7: '7 – Fracassado',
};

/// `tipoIndice` — tipo de índice econômico.
const kTipoIndice = <int, String>{
  1: '1 – Liquidez Corrente',
  2: '2 – Liquidez Geral',
  3: '3 – Liquidez Seca',
  4: '4 – Solvência Geral',
  5: '5 – Endividamento Total',
  6: '6 – Endividamento de Curto Prazo',
  7: '7 – Endividamento de Longo Prazo',
  8: '8 – Outro',
};
