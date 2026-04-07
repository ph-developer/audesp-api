// Domain constants for the Ajuste module (Fase 7).
// Source: AUDESP API ajuste-schema-v2.json + tabelas_organizadas.md

/// `tipoContratoId` — Domínio PNCP: Tipo de Contrato.
const kTipoContrato = <int, String>{
  1: '1 – Contrato',
  2: '2 – Contrato Decorrente de Ata de RP',
  3: '3 – Nota de Empenho',
  4: '4 – Carta Contrato',
  5: '5 – Acordo',
  7: '7 – Empenho',
  8: '8 – Outros',
  12: '12 – Nota de Liquidação',
};

/// `categoriaProcessoId` — Domínio PNCP: Categoria do Processo.
const kCategoriaProcesso = <int, String>{
  1: '1 – Categoria 1',
  2: '2 – Categoria 2',
  3: '3 – Categoria 3',
  4: '4 – Categoria 4',
  5: '5 – Categoria 5',
  6: '6 – Categoria 6',
  7: '7 – Categoria 7',
  8: '8 – Categoria 8',
  9: '9 – Categoria 9',
  10: '10 – Categoria 10',
  11: '11 – Categoria 11',
};

/// `tipoObjetoContrato` — Domínio PNCP: Objeto do Contrato (1-29).
const kTipoObjetoContrato = <int, String>{
  1: '1 – Fornecimento de bens',
  2: '2 – Fornecimento e instalação de bens',
  3: '3 – Arrendamento de bens',
  4: '4 – Locação de bens',
  5: '5 – Concessão de direito real de uso',
  6: '6 – Permissão de uso',
  7: '7 – Prestação de serviços',
  8: '8 – Prestação de serviços de engenharia',
  9: '9 – Prestação de serviços técnicos profissionais especializados',
  10: '10 – Execução de obras',
  11: '11 – Manutenção e conservação de obras',
  12: '12 – Alienação de bens imóveis',
  13: '13 – Alienação de bens móveis',
  14: '14 – Concessão de serviço público',
  15: '15 – Permissão de serviço público',
  16: '16 – Arrendamento de serviço público',
  17: '17 – Parceria Público-Privada na modalidade patrocinada',
  18: '18 – Parceria Público-Privada na modalidade administrativa',
  19: '19 – Concessão de uso de espaço público',
  20: '20 – Permissão de uso de espaço público',
  21: '21 – Contratação integrada',
  22: '22 – Contratação semi-integrada',
  23: '23 – Gestão associada de serviços públicos',
  24: '24 – Instrução, capacitação e desenvolvimento de competências',
  25: '25 – Desenvolvimento de produto de defesa',
  26: '26 – Contratação em âmbito de projeto',
  27: '27 – Aquisição de material',
  28: '28 – Outros',
  29: '29 – Contrato de leilão de bens com disposições especiais',
};

/// `tipoPessoaFornecedor` — tipo de pessoa do fornecedor.
const kTipoPessoaFornecedor = <String, String>{
  'PJ': 'PJ – Pessoa Jurídica',
  'PF': 'PF – Pessoa Física',
  'PE': 'PE – Pessoa Estrangeira',
};

/// `fonteRecursosContratacao` — fontes de recurso (multi-select).
const kFonteRecursoAjuste = <int, String>{
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

/// `tipoTermoContratoId` — Domínio PNCP: Tipo Termo Contrato.
/// A AUDESP permite apenas o valor 2 (Termo Aditivo).
const kTipoTermoContrato = <int, String>{
  2: '2 – Termo Aditivo',
};
