// Domain constants for the Ajuste module (Fase 7).
// Source: AUDESP API ajuste-schema-v2.json + tabelas_organizadas.md

/// `tipoContratoId` — Domínio PNCP: Tipo de Contrato.
const kTipoContrato = <int, String>{
  1: '1 – Contrato (termo inicial)',
  2: '2 – Comodato',
  3: '3 – Arrendamento',
  4: '4 – Concessão',
  5: '5 – Termo de Adesão',
  7: '7 – Empenho',
  8: '8 – Outros',
  12: '12 – Carta Contrato',
};

/// `categoriaProcessoId` — Domínio PNCP: Categoria do Processo.
const kCategoriaProcesso = <int, String>{
  1: '1 – Cessão',
  2: '2 – Compras',
  3: '3 – Informática (TIC)',
  4: '4 – Internacional',
  5: '5 – Locação Imóveis',
  6: '6 – Mão de Obra',
  7: '7 – Obras',
  8: '8 – Serviços',
  9: '9 – Serviços de Engenharia',
  10: '10 – Serviços de Saúde',
  11: '11 – Alienação de bens móveis/imóveis',
};

/// `tipoObjetoContrato` — Domínio AUDESP: Tipo objeto do contrato (1-29).
/// Cada código pertence a uma ou mais categorias de processo:
/// 1-2→categ.1 (Cessão); 3-11→categ.2 (Compras); 12-14→categ.3 (TIC);
/// 15→categ.4; 16→categ.5; 17→categ.6; 18-19→categ.7 ou 9;
/// 20-27→categ.8; 28→categ.10; 29→categ.11.
const kTipoObjetoContrato = <int, String>{
  1: '1 – Permissão',
  2: '2 – Concessão de serviço público',
  3: '3 – Equipamentos e materiais permanentes',
  4: '4 – Material de expediente',
  5: '5 – Medicamentos',
  6: '6 – Material hospitalar, ambulatorial ou odontológico',
  7: '7 – Material escolar',
  8: '8 – Uniforme escolar',
  9: '9 – Gêneros alimentícios',
  10: '10 – Combustíveis e lubrificantes',
  11: '11 – Outros materiais de consumo',
  12: '12 – Compras de TIC',
  13: '13 – Serviços de TIC',
  14: '14 – SIAFIC',
  15: '15 – Internacional',
  16: '16 – Locação de imóveis',
  17: '17 – Locação de mão de obra',
  18: '18 – Implantação de aterro sanitário',
  19: '19 – Outras obras e serviços de engenharia',
  20: '20 – Coleta de Lixo',
  21: '21 – Limpeza urbana/varrição',
  22: '22 – Transporte escolar',
  23: '23 – Publicidade/Propaganda',
  24: '24 – Passagens aéreas e outras despesas de locomoção',
  25: '25 – Serviços de consultoria',
  26: '26 – Operações de crédito (exceto ARO)',
  27: '27 – Outras prestações de serviço',
  28: '28 – Serviços de saúde',
  29: '29 – Alienação de bens móveis/imóveis',
};

/// `tipoPessoaFornecedor` — tipo de pessoa do fornecedor.
const kTipoPessoaFornecedor = <String, String>{
  'PJ': 'PJ – Pessoa Jurídica',
  'PF': 'PF – Pessoa Física',
  'PE': 'PE – Pessoa Estrangeira',
};

/// `fonteRecursosContratacao` — Domínio AUDESP: Fonte de Recursos (multi-select).
const kFonteRecursoAjuste = <int, String>{
  1: '1 – Tesouro',
  2: '2 – Transferências e Convênios Estaduais - Vinculados',
  3: '3 – Recursos Próprios de Fundos Especiais de Despesa - Vinculados',
  4: '4 – Recursos Próprios da Administração Indireta',
  5: '5 – Transferências e Convênios Federais - Vinculados',
  6: '6 – Outras Fontes de Recursos',
  7: '7 – Operações de Crédito',
  8: '8 – Emendas Parlamentares Individuais - Legislativo Municipal',
  91: '91 – Tesouro - Exercícios Anteriores',
  92: '92 – Transferências e Convênios Estaduais - Vinculados - Exercícios Anteriores',
  93: '93 – Recursos Próprios de Fundos Especiais de Despesa - Vinculados - Exercícios Anteriores',
  94: '94 – Recursos Próprios da Administração Indireta - Exercícios Anteriores',
  95: '95 – Transferências e Convênios Federais - Vinculados - Exercícios Anteriores',
  96: '96 – Outras Fontes de Recursos - Exercícios Anteriores',
  97: '97 – Operações de Crédito - Exercícios Anteriores',
  98: '98 – Emendas Parlamentares Individuais - Exercícios Anteriores',
};

/// `tipoTermoContratoId` — Domínio PNCP: Tipo Termo Contrato.
/// A AUDESP permite apenas o valor 2 (Termo Aditivo).
const kTipoTermoContrato = <int, String>{
  2: '2 – Termo Aditivo',
};
