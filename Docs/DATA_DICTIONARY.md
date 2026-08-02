# Dicionário de Dados - WMA Travel ERP

> Documento oficial da estrutura de dados corporativa do WMA Travel ERP.

**Versão do Documento:** 1.0.0
**Última Atualização:** 30/07/2026
**Status:** Em Desenvolvimento

---

## Índice

- [Dicionário de Dados - WMA Travel ERP](#dicionário-de-dados---wma-travel-erp)
  - [Índice](#índice)
  - [1. Visão Geral](#1-visão-geral)
  - [2. Objetivos](#2-objetivos)
  - [3. Escopo](#3-escopo)
  - [4. Convenções](#4-convenções)
  - [Nomenclatura](#nomenclatura)
  - [Chaves Primárias](#chaves-primárias)
  - [Colunas de Auditoria](#colunas-de-auditoria)
  - [5. Estrutura Geral](#5-estrutura-geral)
  - [6. Dicionário das Tabelas](#6-dicionário-das-tabelas)
  - [6.1 Módulo Administrativo](#61-módulo-administrativo)
  - [empresa](#empresa)
    - [Descrição](#descrição)
    - [Finalidade](#finalidade)
    - [Chave Primária](#chave-primária)
    - [Relacionamentos](#relacionamentos)
    - [Colunas](#colunas)
    - [Índices](#índices)
    - [Observações](#observações)
  - [usuario](#usuario)
    - [Descrição](#descrição-1)
    - [Finalidade](#finalidade-1)
    - [Chave Primária](#chave-primária-1)
    - [Relacionamentos](#relacionamentos-1)
    - [Colunas](#colunas-1)
    - [Índices](#índices-1)
    - [Observações](#observações-1)
  - [perfil](#perfil)
    - [Descrição](#descrição-2)
    - [Finalidade](#finalidade-2)
    - [Chave Primária](#chave-primária-2)
    - [Colunas](#colunas-2)
    - [Perfis previstos](#perfis-previstos)
  - [permissao](#permissao)
    - [Descrição](#descrição-3)
    - [Finalidade](#finalidade-3)
    - [Colunas principais](#colunas-principais)
  - [perfil\_permissao](#perfil_permissao)
    - [Descrição](#descrição-4)
    - [Tipo](#tipo)
    - [Relacionamentos](#relacionamentos-2)
    - [Chave composta](#chave-composta)
  - [parametro\_sistema](#parametro_sistema)
    - [Descrição](#descrição-5)
    - [Exemplos](#exemplos)
  - [log\_acesso](#log_acesso)
    - [Descrição](#descrição-6)
    - [Informações registradas](#informações-registradas)
  - [log\_operacao](#log_operacao)
    - [Descrição](#descrição-7)
    - [Eventos](#eventos)
  - [configuracao](#configuracao)
    - [Descrição](#descrição-8)
    - [Exemplos](#exemplos-1)
  - [6.2 Módulo Financeiro](#62-módulo-financeiro)
  - [grupo\_conta](#grupo_conta)
    - [Descrição](#descrição-9)
    - [Finalidade](#finalidade-4)
    - [Exemplos](#exemplos-2)
    - [Chave Primária](#chave-primária-3)
    - [Colunas](#colunas-3)
    - [Relacionamentos](#relacionamentos-3)
  - [categoria\_conta](#categoria_conta)
    - [Descrição](#descrição-10)
    - [Relacionamentos](#relacionamentos-4)
    - [Exemplos](#exemplos-3)
    - [Chave Primária](#chave-primária-4)
    - [Foreign Keys](#foreign-keys)
  - [subcategoria\_conta](#subcategoria_conta)
    - [Descrição](#descrição-11)
    - [Objetivo](#objetivo)
    - [Exemplos](#exemplos-4)
  - [classificacao\_conta](#classificacao_conta)
    - [Descrição](#descrição-12)
    - [Exemplos](#exemplos-5)
  - [plano\_conta](#plano_conta)
    - [Descrição](#descrição-13)
    - [Estrutura](#estrutura)
    - [Colunas](#colunas-4)
  - [centro\_custo](#centro_custo)
    - [Descrição](#descrição-14)
    - [Exemplos](#exemplos-6)
  - [banco](#banco)
    - [Descrição](#descrição-15)
    - [Exemplos](#exemplos-7)
  - [agencia](#agencia)
    - [Descrição](#descrição-16)
  - [conta\_bancaria](#conta_bancaria)
    - [Descrição](#descrição-17)
    - [Informações](#informações)
  - [conta\_financeira](#conta_financeira)
    - [Descrição](#descrição-18)
  - [lancamento\_financeiro](#lancamento_financeiro)
    - [Descrição](#descrição-19)
    - [Responsabilidade](#responsabilidade)
    - [Relacionamentos](#relacionamentos-5)
  - [contas\_receber](#contas_receber)
    - [Descrição](#descrição-20)
    - [Situações](#situações)
  - [contas\_pagar](#contas_pagar)
    - [Descrição](#descrição-21)
    - [Situações](#situações-1)
  - [fluxo\_caixa](#fluxo_caixa)
    - [Descrição](#descrição-22)
    - [Indicadores](#indicadores)
  - [conciliacao\_bancaria](#conciliacao_bancaria)
    - [Descrição](#descrição-23)
    - [Objetivo](#objetivo-1)
  - [dre](#dre)
    - [Descrição](#descrição-24)
    - [Indicadores](#indicadores-1)
  - [balancete](#balancete)
    - [Descrição](#descrição-25)
  - [aporte\_capital](#aporte_capital)
    - [Descrição](#descrição-26)
    - [Informações](#informações-1)
  - [distribuicao\_lucros](#distribuicao_lucros)
    - [Descrição](#descrição-27)
    - [Relacionamentos](#relacionamentos-6)
  - [transferencia\_financeira](#transferencia_financeira)
    - [Descrição](#descrição-28)
    - [Exemplos](#exemplos-8)
  - [historico\_financeiro](#historico_financeiro)
    - [Descrição](#descrição-29)
  - [fechamento\_financeiro](#fechamento_financeiro)
    - [Descrição](#descrição-30)
    - [Objetivos](#objetivos)
  - [indicador\_financeiro](#indicador_financeiro)
    - [Descrição](#descrição-31)
    - [Exemplos](#exemplos-9)
  - [dashboard\_financeiro](#dashboard_financeiro)
    - [Descrição](#descrição-32)
  - [6.3 Módulo Comercial](#63-módulo-comercial)
  - [Visão Geral](#visão-geral)
  - [Objetivos](#objetivos-1)
  - [cliente](#cliente)
    - [Descrição](#descrição-33)
    - [Responsabilidade](#responsabilidade-1)
    - [Chave Primária](#chave-primária-5)
    - [Relacionamentos](#relacionamentos-7)
    - [Colunas](#colunas-5)
    - [Índices](#índices-2)
    - [Observações](#observações-2)
  - [fornecedor](#fornecedor)
    - [Descrição](#descrição-34)
    - [Finalidade](#finalidade-5)
    - [Exemplos](#exemplos-10)
  - [contato](#contato)
    - [Descrição](#descrição-35)
    - [Exemplos](#exemplos-11)
  - [endereco](#endereco)
    - [Descrição](#descrição-36)
    - [Utilização](#utilização)
    - [Tipos](#tipos)
  - [lead](#lead)
    - [Descrição](#descrição-37)
    - [Responsabilidade](#responsabilidade-2)
    - [Situações](#situações-2)
  - [origem\_lead](#origem_lead)
    - [Descrição](#descrição-38)
    - [Exemplos](#exemplos-12)
  - [crm](#crm)
    - [Descrição](#descrição-39)
    - [Objetivo](#objetivo-2)
  - [oportunidade](#oportunidade)
    - [Descrição](#descrição-40)
    - [Situações](#situações-3)
  - [funil\_venda](#funil_venda)
    - [Descrição](#descrição-41)
    - [Etapas](#etapas)
  - [proposta](#proposta)
    - [Descrição](#descrição-42)
    - [Informações](#informações-2)
    - [Situações](#situações-4)
  - [contrato](#contrato)
    - [Descrição](#descrição-43)
    - [Pode representar](#pode-representar)
  - [venda](#venda)
    - [Descrição](#descrição-44)
    - [Relacionamentos](#relacionamentos-8)
  - [item\_venda](#item_venda)
    - [Descrição](#descrição-45)
    - [Exemplos](#exemplos-13)
  - [campanha](#campanha)
    - [Descrição](#descrição-46)
    - [Exemplos](#exemplos-14)
  - [historico\_cliente](#historico_cliente)
    - [Descrição](#descrição-47)
    - [Eventos](#eventos-1)
  - [avaliacao\_cliente](#avaliacao_cliente)
    - [Descrição](#descrição-48)
    - [Indicadores](#indicadores-2)
  - [documento\_cliente](#documento_cliente)
    - [Descrição](#descrição-49)
    - [Exemplos](#exemplos-15)
  - [comissao\_vendedor](#comissao_vendedor)
    - [Descrição](#descrição-50)
    - [Informações](#informações-3)
  - [vendedor](#vendedor)
    - [Descrição](#descrição-51)
    - [Indicadores](#indicadores-3)
  - [meta\_comercial](#meta_comercial)
    - [Descrição](#descrição-52)
    - [Controle](#controle)
  - [dashboard\_comercial](#dashboard_comercial)
    - [Descrição](#descrição-53)
    - [Indicadores](#indicadores-4)
  - [Fluxo Comercial](#fluxo-comercial)
  - [Indicadores Comerciais](#indicadores-comerciais)
  - [6.4 Módulo Fiscal](#64-módulo-fiscal)
    - [Visão Geral](#visão-geral-1)
    - [Objetivos](#objetivos-2)
  - [documento\_fiscal](#documento_fiscal)
    - [Descrição](#descrição-54)
    - [Chave Primária](#chave-primária-6)
    - [Relacionamentos](#relacionamentos-9)
    - [Colunas](#colunas-6)
    - [Índices](#índices-3)
  - [nota\_fiscal](#nota_fiscal)
    - [Descrição](#descrição-55)
    - [Tipos](#tipos-1)
    - [Situações](#situações-5)
  - [item\_nota\_fiscal](#item_nota_fiscal)
    - [Descrição](#descrição-56)
    - [Informações](#informações-4)
  - [imposto](#imposto)
    - [Descrição](#descrição-57)
    - [Exemplos](#exemplos-16)
  - [aliquota\_imposto](#aliquota_imposto)
    - [Descrição](#descrição-58)
    - [Informações](#informações-5)
  - [apuracao\_imposto](#apuracao_imposto)
    - [Descrição](#descrição-59)
    - [Indicadores](#indicadores-5)
  - [guia\_recolhimento](#guia_recolhimento)
    - [Descrição](#descrição-60)
    - [Exemplos](#exemplos-17)
  - [obrigacao\_acessoria](#obrigacao_acessoria)
    - [Descrição](#descrição-61)
    - [Exemplos](#exemplos-18)
  - [declaracao\_fiscal](#declaracao_fiscal)
    - [Descrição](#descrição-62)
    - [Situações](#situações-6)
  - [retenção\_imposto](#retenção_imposto)
    - [Descrição](#descrição-63)
    - [Exemplos](#exemplos-19)
  - [municipio](#municipio)
    - [Descrição](#descrição-64)
    - [Relacionamentos](#relacionamentos-10)
  - [estado](#estado)
    - [Descrição](#descrição-65)
    - [Campos](#campos)
  - [natureza\_operacao](#natureza_operacao)
    - [Descrição](#descrição-66)
    - [Exemplos](#exemplos-20)
  - [cfop](#cfop)
    - [Descrição](#descrição-67)
    - [Objetivo](#objetivo-3)
  - [cst](#cst)
    - [Descrição](#descrição-68)
    - [Exemplos](#exemplos-21)
  - [ncm](#ncm)
    - [Descrição](#descrição-69)
  - [certificado\_digital](#certificado_digital)
    - [Descrição](#descrição-70)
    - [Informações](#informações-6)
  - [integracao\_sefaz](#integracao_sefaz)
    - [Descrição](#descrição-71)
    - [Eventos](#eventos-2)
  - [integracao\_prefeitura](#integracao_prefeitura)
    - [Descrição](#descrição-72)
    - [Informações](#informações-7)
  - [dashboard\_fiscal](#dashboard_fiscal)
    - [Descrição](#descrição-73)
    - [Indicadores](#indicadores-6)
  - [Fluxo Fiscal](#fluxo-fiscal)
  - [Indicadores Fiscais](#indicadores-fiscais)
  - [6.5 Módulo Turismo](#65-módulo-turismo)
    - [Visão Geral](#visão-geral-2)
    - [Objetivos](#objetivos-3)
  - [pacote\_turistico](#pacote_turistico)
    - [Descrição](#descrição-74)
    - [Finalidade](#finalidade-6)
    - [Chave Primária](#chave-primária-7)
    - [Relacionamentos](#relacionamentos-11)
    - [Colunas](#colunas-7)
    - [Índices](#índices-4)
  - [categoria\_pacote](#categoria_pacote)
    - [Descrição](#descrição-75)
    - [Exemplos](#exemplos-22)
  - [destino](#destino)
    - [Descrição](#descrição-76)
    - [Exemplos](#exemplos-23)
    - [Relacionamentos](#relacionamentos-12)
  - [roteiro](#roteiro)
    - [Descrição](#descrição-77)
    - [Informações](#informações-8)
  - [reserva](#reserva)
    - [Descrição](#descrição-78)
    - [Relacionamentos](#relacionamentos-13)
    - [Situações](#situações-7)
  - [passageiro](#passageiro)
    - [Descrição](#descrição-79)
    - [Informações](#informações-9)
  - [reserva\_passageiro](#reserva_passageiro)
    - [Descrição](#descrição-80)
    - [Tipo](#tipo-1)
  - [hotel](#hotel)
    - [Descrição](#descrição-81)
    - [Informações](#informações-10)
  - [acomodacao](#acomodacao)
    - [Descrição](#descrição-82)
    - [Exemplos](#exemplos-24)
  - [voo](#voo)
    - [Descrição](#descrição-83)
    - [Informações](#informações-11)
  - [companhia\_aerea](#companhia_aerea)
    - [Descrição](#descrição-84)
    - [Exemplos](#exemplos-25)
  - [transporte](#transporte)
    - [Descrição](#descrição-85)
    - [Exemplos](#exemplos-26)
  - [passeio](#passeio)
    - [Descrição](#descrição-86)
    - [Exemplos](#exemplos-27)
  - [guia\_turismo](#guia_turismo)
    - [Descrição](#descrição-87)
    - [Informações](#informações-12)
  - [fornecedor\_turistico](#fornecedor_turistico)
    - [Descrição](#descrição-88)
    - [Exemplos](#exemplos-28)
  - [voucher](#voucher)
    - [Descrição](#descrição-89)
    - [Informações](#informações-13)
  - [seguro\_viagem](#seguro_viagem)
    - [Descrição](#descrição-90)
    - [Informações](#informações-14)
  - [embarque](#embarque)
    - [Descrição](#descrição-91)
    - [Informações](#informações-15)
  - [excursao](#excursao)
    - [Descrição](#descrição-92)
    - [Informações](#informações-16)
  - [calendario\_viagem](#calendario_viagem)
    - [Descrição](#descrição-93)
    - [Objetivo](#objetivo-4)
  - [ocorrencia\_viagem](#ocorrencia_viagem)
    - [Descrição](#descrição-94)
    - [Exemplos](#exemplos-29)
  - [avaliacao\_viagem](#avaliacao_viagem)
    - [Descrição](#descrição-95)
    - [Indicadores](#indicadores-7)
  - [dashboard\_turismo](#dashboard_turismo)
    - [Descrição](#descrição-96)
    - [Indicadores](#indicadores-8)
  - [Fluxo Operacional](#fluxo-operacional)
  - [Indicadores do Turismo](#indicadores-do-turismo)
  - [6.6 Módulo Bike Tour](#66-módulo-bike-tour)
    - [Visão Geral](#visão-geral-3)
    - [Objetivos](#objetivos-4)
  - [evento\_bike](#evento_bike)
    - [Descrição](#descrição-97)
    - [Finalidade](#finalidade-7)
    - [Chave Primária](#chave-primária-8)
    - [Relacionamentos](#relacionamentos-14)
    - [Colunas](#colunas-8)
    - [Índices](#índices-5)
  - [categoria\_evento](#categoria_evento)
    - [Descrição](#descrição-98)
    - [Exemplos](#exemplos-30)
  - [roteiro\_bike](#roteiro_bike)
    - [Descrição](#descrição-99)
    - [Informações](#informações-17)
  - [percurso\_bike](#percurso_bike)
    - [Descrição](#descrição-100)
    - [Informações](#informações-18)
  - [inscricao\_bike](#inscricao_bike)
    - [Descrição](#descrição-101)
    - [Situações](#situações-8)
  - [participante\_bike](#participante_bike)
    - [Descrição](#descrição-102)
    - [Informações](#informações-19)
  - [bicicleta](#bicicleta)
    - [Descrição](#descrição-103)
    - [Exemplos](#exemplos-31)
  - [categoria\_bicicleta](#categoria_bicicleta)
    - [Descrição](#descrição-104)
    - [Exemplos](#exemplos-32)
  - [kit\_evento](#kit_evento)
    - [Descrição](#descrição-105)
    - [Itens](#itens)
  - [entrega\_kit](#entrega_kit)
    - [Descrição](#descrição-106)
    - [Informações](#informações-20)
  - [apoio\_evento](#apoio_evento)
    - [Descrição](#descrição-107)
    - [Exemplos](#exemplos-33)
  - [ponto\_controle](#ponto_controle)
    - [Descrição](#descrição-108)
    - [Informações](#informações-21)
  - [checkin\_participante](#checkin_participante)
    - [Descrição](#descrição-109)
    - [Objetivo](#objetivo-5)
  - [ocorrencia\_evento](#ocorrencia_evento)
    - [Descrição](#descrição-110)
    - [Exemplos](#exemplos-34)
  - [patrocinador](#patrocinador)
    - [Descrição](#descrição-111)
    - [Informações](#informações-22)
  - [parceiro\_evento](#parceiro_evento)
    - [Descrição](#descrição-112)
    - [Exemplos](#exemplos-35)
  - [cronometragem](#cronometragem)
    - [Descrição](#descrição-113)
    - [Informações](#informações-23)
  - [classificacao\_evento](#classificacao_evento)
    - [Descrição](#descrição-114)
    - [Critérios](#critérios)
  - [certificado\_participacao](#certificado_participacao)
    - [Descrição](#descrição-115)
    - [Informações](#informações-24)
  - [avaliacao\_evento](#avaliacao_evento)
    - [Descrição](#descrição-116)
    - [Indicadores](#indicadores-9)
  - [dashboard\_bike](#dashboard_bike)
    - [Descrição](#descrição-117)
    - [Indicadores](#indicadores-10)
    - [Fluxo Operacional](#fluxo-operacional-1)
  - [Indicadores do Bike Tour](#indicadores-do-bike-tour)
  - [6.7 Módulo Recursos Humanos](#67-módulo-recursos-humanos)
    - [Visão Geral](#visão-geral-4)
    - [Objetivos](#objetivos-5)
  - [colaborador](#colaborador)
    - [Descrição](#descrição-118)
    - [Finalidade](#finalidade-8)
    - [Chave Primária](#chave-primária-9)
    - [Relacionamentos](#relacionamentos-15)
    - [Colunas](#colunas-9)
    - [Índices](#índices-6)
  - [departamento](#departamento)
    - [Descrição](#descrição-119)
    - [Exemplos](#exemplos-36)
  - [cargo](#cargo)
    - [Descrição](#descrição-120)
    - [Exemplos](#exemplos-37)
  - [jornada\_trabalho](#jornada_trabalho)
    - [Descrição](#descrição-121)
    - [Exemplos](#exemplos-38)
  - [ponto](#ponto)
    - [Descrição](#descrição-122)
    - [Informações](#informações-25)
  - [banco\_horas](#banco_horas)
    - [Descrição](#descrição-123)
    - [Indicadores](#indicadores-11)
  - [folha\_pagamento](#folha_pagamento)
    - [Descrição](#descrição-124)
    - [Componentes](#componentes)
  - [beneficio](#beneficio)
    - [Descrição](#descrição-125)
    - [Exemplos](#exemplos-39)
  - [colaborador\_beneficio](#colaborador_beneficio)
    - [Descrição](#descrição-126)
    - [Tipo](#tipo-2)
  - [ferias](#ferias)
    - [Descrição](#descrição-127)
    - [Informações](#informações-26)
  - [afastamento](#afastamento)
    - [Descrição](#descrição-128)
    - [Exemplos](#exemplos-40)
  - [treinamento](#treinamento)
    - [Descrição](#descrição-129)
    - [Exemplos](#exemplos-41)
  - [colaborador\_treinamento](#colaborador_treinamento)
    - [Descrição](#descrição-130)
  - [avaliacao\_desempenho](#avaliacao_desempenho)
    - [Descrição](#descrição-131)
    - [Critérios](#critérios-1)
  - [dashboard\_rh](#dashboard_rh)
    - [Descrição](#descrição-132)
    - [Indicadores](#indicadores-12)
    - [Fluxo Operacional](#fluxo-operacional-2)
  - [Indicadores de Recursos Humanos](#indicadores-de-recursos-humanos)
  - [6.8 Framework de Auditoria](#68-framework-de-auditoria)
    - [Visão Geral](#visão-geral-5)
    - [Objetivos](#objetivos-6)
  - [execucao\_auditoria](#execucao_auditoria)
    - [Descrição](#descrição-133)
    - [Chave Primária](#chave-primária-10)
    - [Colunas](#colunas-10)
    - [Índices](#índices-7)
  - [auditoria\_categoria](#auditoria_categoria)
    - [Descrição](#descrição-134)
    - [Exemplos](#exemplos-42)
  - [auditoria\_item](#auditoria_item)
    - [Descrição](#descrição-135)
    - [Exemplos](#exemplos-43)
  - [auditoria\_resultado](#auditoria_resultado)
    - [Descrição](#descrição-136)
    - [Situações](#situações-9)
    - [Relacionamentos](#relacionamentos-16)
  - [auditoria\_score](#auditoria_score)
    - [Descrição](#descrição-137)
    - [Indicadores](#indicadores-13)
  - [auditoria\_certificacao](#auditoria_certificacao)
    - [Descrição](#descrição-138)
    - [Classificações](#classificações)
  - [plano\_correcao](#plano_correcao)
    - [Descrição](#descrição-139)
    - [Informações](#informações-27)
  - [plano\_correcao\_item](#plano_correcao_item)
    - [Descrição](#descrição-140)
  - [revalidacao](#revalidacao)
    - [Descrição](#descrição-141)
    - [Objetivo](#objetivo-6)
  - [auditoria\_objeto](#auditoria_objeto)
    - [Descrição](#descrição-142)
    - [Tipos](#tipos-2)
  - [auditoria\_documentacao](#auditoria_documentacao)
    - [Descrição](#descrição-143)
    - [Critérios](#critérios-2)
  - [auditoria\_indices](#auditoria_indices)
    - [Descrição](#descrição-144)
    - [Verificações](#verificações)
  - [auditoria\_fk](#auditoria_fk)
    - [Descrição](#descrição-145)
    - [Critérios](#critérios-3)
  - [auditoria\_performance](#auditoria_performance)
    - [Descrição](#descrição-146)
    - [Métricas](#métricas)
  - [auditoria\_seguranca](#auditoria_seguranca)
    - [Descrição](#descrição-147)
    - [Critérios](#critérios-4)
  - [auditoria\_healthcheck](#auditoria_healthcheck)
    - [Descrição](#descrição-148)
    - [Exemplos](#exemplos-44)
  - [dashboard\_auditoria](#dashboard_auditoria)
    - [Descrição](#descrição-149)
    - [Indicadores](#indicadores-14)
  - [Fluxo da Auditoria](#fluxo-da-auditoria)
  - [Índice de Conformidade do Banco (ICB)](#índice-de-conformidade-do-banco-icb)
  - [Faixas](#faixas)
  - [Indicadores Técnicos](#indicadores-técnicos)
  - [6.9 Framework de Governança](#69-framework-de-governança)
    - [Visão Geral](#visão-geral-6)
    - [Objetivos](#objetivos-7)
  - [governanca\_politica](#governanca_politica)
    - [Descrição](#descrição-150)
    - [Exemplos](#exemplos-45)
  - [governanca\_categoria](#governanca_categoria)
    - [Descrição](#descrição-151)
    - [Exemplos](#exemplos-46)
  - [governanca\_documento](#governanca_documento)
    - [Descrição](#descrição-152)
    - [Exemplos](#exemplos-47)
  - [governanca\_versao](#governanca_versao)
    - [Descrição](#descrição-153)
    - [Informações](#informações-28)
  - [governanca\_release](#governanca_release)
    - [Descrição](#descrição-154)
    - [Exemplos](#exemplos-48)
  - [governanca\_migracao](#governanca_migracao)
    - [Descrição](#descrição-155)
    - [Informações](#informações-29)
  - [governanca\_change](#governanca_change)
    - [Descrição](#descrição-156)
    - [Eventos](#eventos-3)
  - [governanca\_aprovacao](#governanca_aprovacao)
    - [Descrição](#descrição-157)
    - [Fluxo](#fluxo)
  - [governanca\_risco](#governanca_risco)
    - [Descrição](#descrição-158)
    - [Classificações](#classificações-1)
  - [governanca\_incidente](#governanca_incidente)
    - [Descrição](#descrição-159)
    - [Exemplos](#exemplos-49)
  - [governanca\_lgpd](#governanca_lgpd)
    - [Descrição](#descrição-160)
    - [Informações](#informações-30)
  - [governanca\_log](#governanca_log)
    - [Descrição](#descrição-161)
    - [Exemplos](#exemplos-50)
  - [governanca\_backup](#governanca_backup)
    - [Descrição](#descrição-162)
    - [Informações](#informações-31)
  - [governanca\_restore](#governanca_restore)
    - [Descrição](#descrição-163)
    - [Objetivo](#objetivo-7)
  - [governanca\_ambiente](#governanca_ambiente)
    - [Descrição](#descrição-164)
    - [Exemplos](#exemplos-51)
  - [governanca\_servidor](#governanca_servidor)
    - [Descrição](#descrição-165)
    - [Informações](#informações-32)
  - [governanca\_role](#governanca_role)
    - [Descrição](#descrição-166)
    - [Exemplos](#exemplos-52)
  - [governanca\_permissao](#governanca_permissao)
    - [Descrição](#descrição-167)
    - [Objetivos](#objetivos-8)
  - [governanca\_compliance](#governanca_compliance)
    - [Descrição](#descrição-168)
    - [Critérios](#critérios-5)
  - [governanca\_metadata](#governanca_metadata)
    - [Descrição](#descrição-169)
    - [Conteúdo](#conteúdo)
  - [dashboard\_governanca](#dashboard_governanca)
    - [Descrição](#descrição-170)
    - [Indicadores](#indicadores-15)
  - [Fluxo de Governança](#fluxo-de-governança)
  - [Indicadores de Governança](#indicadores-de-governança)
  - [Integração com Outros Frameworks](#integração-com-outros-frameworks)
  - [Benefícios](#benefícios)
  - [6.10 Views](#610-views)
    - [Objetivos](#objetivos-9)
  - [Convenções](#convenções)
  - [Classificação](#classificação)
  - [vw\_empresa](#vw_empresa)
    - [Descrição](#descrição-171)
    - [Origem](#origem)
    - [Utilização](#utilização-1)
  - [vw\_clientes](#vw_clientes)
    - [Descrição](#descrição-172)
    - [Origem](#origem-1)
    - [Campos principais](#campos-principais)
  - [vw\_fornecedores](#vw_fornecedores)
    - [Descrição](#descrição-173)
    - [Origem](#origem-2)
  - [vw\_colaboradores](#vw_colaboradores)
    - [Descrição](#descrição-174)
    - [Origem](#origem-3)
  - [vw\_contas\_receber](#vw_contas_receber)
    - [Descrição](#descrição-175)
    - [Origem](#origem-4)
    - [Indicadores](#indicadores-16)
  - [vw\_contas\_pagar](#vw_contas_pagar)
    - [Descrição](#descrição-176)
    - [Origem](#origem-5)
  - [vw\_fluxo\_caixa](#vw_fluxo_caixa)
    - [Descrição](#descrição-177)
    - [Origem](#origem-6)
    - [Indicadores](#indicadores-17)
  - [vw\_dre](#vw_dre)
    - [Descrição](#descrição-178)
    - [Origem](#origem-7)
    - [Indicadores](#indicadores-18)
  - [vw\_balancete](#vw_balancete)
    - [Descrição](#descrição-179)
    - [Origem](#origem-8)
  - [vw\_reservas](#vw_reservas)
    - [Descrição](#descrição-180)
    - [Origem](#origem-9)
  - [vw\_pacotes](#vw_pacotes)
    - [Descrição](#descrição-181)
    - [Origem](#origem-10)
  - [vw\_eventos\_bike](#vw_eventos_bike)
    - [Descrição](#descrição-182)
    - [Origem](#origem-11)
  - [vw\_participantes\_bike](#vw_participantes_bike)
    - [Descrição](#descrição-183)
    - [Origem](#origem-12)
  - [vw\_dashboard\_financeiro](#vw_dashboard_financeiro)
    - [Descrição](#descrição-184)
    - [Indicadores](#indicadores-19)
  - [vw\_dashboard\_comercial](#vw_dashboard_comercial)
    - [Descrição](#descrição-185)
    - [Indicadores](#indicadores-20)
  - [vw\_dashboard\_turismo](#vw_dashboard_turismo)
    - [Descrição](#descrição-186)
    - [Indicadores](#indicadores-21)
  - [vw\_dashboard\_bike](#vw_dashboard_bike)
    - [Descrição](#descrição-187)
    - [Indicadores](#indicadores-22)
  - [vw\_dashboard\_rh](#vw_dashboard_rh)
    - [Descrição](#descrição-188)
    - [Indicadores](#indicadores-23)
  - [vw\_dashboard\_fiscal](#vw_dashboard_fiscal)
    - [Descrição](#descrição-189)
    - [Indicadores](#indicadores-24)
  - [vw\_dashboard\_governanca](#vw_dashboard_governanca)
    - [Descrição](#descrição-190)
    - [Indicadores](#indicadores-25)
  - [vw\_dashboard\_auditoria](#vw_dashboard_auditoria)
    - [Descrição](#descrição-191)
    - [Indicadores](#indicadores-26)
  - [vw\_health\_check](#vw_health_check)
    - [Descrição](#descrição-192)
    - [Indicadores](#indicadores-27)
  - [vw\_indicadores\_auditoria](#vw_indicadores_auditoria)
    - [Descrição](#descrição-193)
    - [Origem](#origem-13)
    - [Indicadores](#indicadores-28)
  - [Dependências](#dependências)
  - [Boas Práticas](#boas-práticas)
  - [Convenções de Nomenclatura](#convenções-de-nomenclatura)
  - [Indicadores Cobertos](#indicadores-cobertos)
  - [Estatísticas do Projeto](#estatísticas-do-projeto)
  - [6.11 Procedures](#611-procedures)
    - [Objetivos](#objetivos-10)
    - [Convenções](#convenções-1)
  - [Organização](#organização)
  - [Estrutura da Documentação](#estrutura-da-documentação)
  - [Procedures Administrativas](#procedures-administrativas)
  - [sp\_cadastrar\_empresa](#sp_cadastrar_empresa)
    - [Descrição](#descrição-194)
    - [Objetivo](#objetivo-8)
    - [Parâmetros](#parâmetros)
    - [Retorno](#retorno)
  - [sp\_atualizar\_empresa](#sp_atualizar_empresa)
    - [Descrição](#descrição-195)
  - [sp\_inativar\_empresa](#sp_inativar_empresa)
    - [Descrição](#descrição-196)
  - [Procedures Financeiras](#procedures-financeiras)
  - [sp\_gerar\_fluxo\_caixa](#sp_gerar_fluxo_caixa)
    - [Descrição](#descrição-197)
    - [Responsabilidade](#responsabilidade-3)
  - [sp\_recalcular\_saldos](#sp_recalcular_saldos)
    - [Descrição](#descrição-198)
  - [sp\_fechamento\_financeiro](#sp_fechamento_financeiro)
    - [Descrição](#descrição-199)
    - [Processos](#processos)
  - [sp\_abrir\_competencia](#sp_abrir_competencia)
    - [Descrição](#descrição-200)
  - [sp\_fechar\_competencia](#sp_fechar_competencia)
    - [Descrição](#descrição-201)
  - [sp\_reabrir\_competencia](#sp_reabrir_competencia)
    - [Descrição](#descrição-202)
  - [sp\_calcular\_dre](#sp_calcular_dre)
    - [Descrição](#descrição-203)
  - [sp\_calcular\_balancete](#sp_calcular_balancete)
    - [Descrição](#descrição-204)
  - [Procedures Comerciais](#procedures-comerciais)
  - [sp\_converter\_lead](#sp_converter_lead)
    - [Descrição](#descrição-205)
  - [sp\_gerar\_proposta](#sp_gerar_proposta)
    - [Descrição](#descrição-206)
  - [sp\_fechar\_venda](#sp_fechar_venda)
    - [Descrição](#descrição-207)
  - [sp\_cancelar\_venda](#sp_cancelar_venda)
    - [Descrição](#descrição-208)
  - [Procedures Fiscais](#procedures-fiscais)
  - [sp\_emitir\_nf](#sp_emitir_nf)
    - [Descrição](#descrição-209)
  - [sp\_cancelar\_nf](#sp_cancelar_nf)
    - [Descrição](#descrição-210)
  - [sp\_apurar\_impostos](#sp_apurar_impostos)
    - [Descrição](#descrição-211)
  - [sp\_gerar\_das](#sp_gerar_das)
    - [Descrição](#descrição-212)
  - [sp\_gerar\_darf](#sp_gerar_darf)
    - [Descrição](#descrição-213)
  - [Procedures Turismo](#procedures-turismo)
  - [sp\_confirmar\_reserva](#sp_confirmar_reserva)
    - [Descrição](#descrição-214)
  - [sp\_cancelar\_reserva](#sp_cancelar_reserva)
    - [Descrição](#descrição-215)
  - [sp\_emitir\_voucher](#sp_emitir_voucher)
    - [Descrição](#descrição-216)
  - [sp\_gerar\_roteiro](#sp_gerar_roteiro)
    - [Descrição](#descrição-217)
  - [Procedures Bike Tour](#procedures-bike-tour)
  - [sp\_confirmar\_inscricao](#sp_confirmar_inscricao)
    - [Descrição](#descrição-218)
  - [sp\_entregar\_kit](#sp_entregar_kit)
    - [Descrição](#descrição-219)
  - [sp\_registrar\_checkin](#sp_registrar_checkin)
    - [Descrição](#descrição-220)
  - [sp\_classificar\_evento](#sp_classificar_evento)
    - [Descrição](#descrição-221)
  - [sp\_emitir\_certificado](#sp_emitir_certificado)
    - [Descrição](#descrição-222)
  - [Procedures RH](#procedures-rh)
  - [sp\_calcular\_folha](#sp_calcular_folha)
    - [Descrição](#descrição-223)
  - [sp\_calcular\_ferias](#sp_calcular_ferias)
    - [Descrição](#descrição-224)
  - [sp\_processar\_ponto](#sp_processar_ponto)
    - [Descrição](#descrição-225)
  - [Procedures Auditoria](#procedures-auditoria)
  - [sp\_executar\_auditoria](#sp_executar_auditoria)
    - [Descrição](#descrição-226)
  - [sp\_auditar\_colunas](#sp_auditar_colunas)
    - [Descrição](#descrição-227)
  - [sp\_auditar\_indices](#sp_auditar_indices)
    - [Descrição](#descrição-228)
  - [sp\_auditar\_documentacao](#sp_auditar_documentacao)
    - [Descrição](#descrição-229)
  - [sp\_auditar\_seguranca](#sp_auditar_seguranca)
    - [Descrição](#descrição-230)
  - [sp\_calcular\_score](#sp_calcular_score)
    - [Descrição](#descrição-231)
  - [sp\_calcular\_icb](#sp_calcular_icb)
    - [Descrição](#descrição-232)
  - [sp\_gerar\_plano\_correcao](#sp_gerar_plano_correcao)
    - [Descrição](#descrição-233)
  - [sp\_revalidar\_banco](#sp_revalidar_banco)
    - [Descrição](#descrição-234)
  - [sp\_certificar\_banco](#sp_certificar_banco)
    - [Descrição](#descrição-235)
  - [Procedures Governança](#procedures-governança)
  - [sp\_registrar\_release](#sp_registrar_release)
    - [Descrição](#descrição-236)
  - [sp\_registrar\_migracao](#sp_registrar_migracao)
    - [Descrição](#descrição-237)
  - [sp\_registrar\_backup](#sp_registrar_backup)
    - [Descrição](#descrição-238)
  - [sp\_registrar\_restore](#sp_registrar_restore)
    - [Descrição](#descrição-239)
  - [sp\_atualizar\_metadata](#sp_atualizar_metadata)
    - [Descrição](#descrição-240)
  - [Procedures do Sistema](#procedures-do-sistema)
  - [sp\_health\_check](#sp_health_check)
    - [Descrição](#descrição-241)
  - [sp\_limpeza\_logs](#sp_limpeza_logs)
    - [Descrição](#descrição-242)
  - [sp\_reindex\_database](#sp_reindex_database)
    - [Descrição](#descrição-243)
  - [sp\_vacuum\_database](#sp_vacuum_database)
    - [Descrição](#descrição-244)
  - [sp\_analyze\_database](#sp_analyze_database)
    - [Descrição](#descrição-245)
    - [Convenções](#convenções-2)
    - [Dependências](#dependências-1)
    - [Estatísticas Previstas](#estatísticas-previstas)
  - [6.12 Functions](#612-functions)
    - [Objetivos](#objetivos-11)
    - [Convenções](#convenções-3)
    - [Classificação](#classificação-1)
    - [Estrutura da Documentação](#estrutura-da-documentação-1)
  - [Functions Utilitárias](#functions-utilitárias)
  - [fn\_uuid](#fn_uuid)
    - [Descrição](#descrição-246)
    - [Retorno](#retorno-1)
  - [fn\_now\_brasil](#fn_now_brasil)
    - [Descrição](#descrição-247)
    - [Retorno](#retorno-2)
  - [fn\_normalizar\_texto](#fn_normalizar_texto)
    - [Descrição](#descrição-248)
    - [Retorno](#retorno-3)
  - [fn\_remover\_caracteres\_especiais](#fn_remover_caracteres_especiais)
    - [Descrição](#descrição-249)
  - [fn\_formatar\_documento](#fn_formatar_documento)
    - [Descrição](#descrição-250)
  - [Functions Financeiras](#functions-financeiras)
  - [fn\_calcular\_saldo](#fn_calcular_saldo)
    - [Descrição](#descrição-251)
    - [Retorno](#retorno-4)
  - [fn\_calcular\_fluxo\_caixa](#fn_calcular_fluxo_caixa)
    - [Descrição](#descrição-252)
  - [fn\_calcular\_dre](#fn_calcular_dre)
    - [Descrição](#descrição-253)
  - [fn\_calcular\_balancete](#fn_calcular_balancete)
    - [Descrição](#descrição-254)
  - [fn\_calcular\_ticket\_medio](#fn_calcular_ticket_medio)
    - [Descrição](#descrição-255)
  - [fn\_calcular\_lucro](#fn_calcular_lucro)
    - [Descrição](#descrição-256)
  - [fn\_calcular\_markup](#fn_calcular_markup)
    - [Descrição](#descrição-257)
  - [fn\_calcular\_margem](#fn_calcular_margem)
    - [Descrição](#descrição-258)
  - [Functions Comerciais](#functions-comerciais)
  - [fn\_total\_vendas\_cliente](#fn_total_vendas_cliente)
    - [Descrição](#descrição-259)
  - [fn\_total\_pedidos](#fn_total_pedidos)
    - [Descrição](#descrição-260)
  - [fn\_total\_clientes\_ativos](#fn_total_clientes_ativos)
    - [Descrição](#descrição-261)
  - [fn\_calcular\_comissao](#fn_calcular_comissao)
    - [Descrição](#descrição-262)
  - [Functions Fiscais](#functions-fiscais)
  - [fn\_calcular\_simples](#fn_calcular_simples)
    - [Descrição](#descrição-263)
  - [fn\_calcular\_iss](#fn_calcular_iss)
    - [Descrição](#descrição-264)
  - [fn\_calcular\_pis](#fn_calcular_pis)
    - [Descrição](#descrição-265)
  - [fn\_calcular\_cofins](#fn_calcular_cofins)
    - [Descrição](#descrição-266)
  - [fn\_calcular\_irpj](#fn_calcular_irpj)
    - [Descrição](#descrição-267)
  - [fn\_calcular\_csll](#fn_calcular_csll)
    - [Descrição](#descrição-268)
  - [Functions Turismo](#functions-turismo)
  - [fn\_calcular\_valor\_pacote](#fn_calcular_valor_pacote)
    - [Descrição](#descrição-269)
  - [fn\_calcular\_desconto](#fn_calcular_desconto)
    - [Descrição](#descrição-270)
  - [fn\_disponibilidade\_pacote](#fn_disponibilidade_pacote)
    - [Descrição](#descrição-271)
  - [fn\_total\_reservas](#fn_total_reservas)
    - [Descrição](#descrição-272)
  - [Functions Bike Tour](#functions-bike-tour)
  - [fn\_calcular\_pontuacao](#fn_calcular_pontuacao)
    - [Descrição](#descrição-273)
  - [fn\_calcular\_classificacao](#fn_calcular_classificacao)
    - [Descrição](#descrição-274)
  - [fn\_total\_participantes](#fn_total_participantes)
    - [Descrição](#descrição-275)
  - [Functions RH](#functions-rh)
  - [fn\_calcular\_salario](#fn_calcular_salario)
    - [Descrição](#descrição-276)
  - [fn\_calcular\_ferias](#fn_calcular_ferias)
    - [Descrição](#descrição-277)
  - [fn\_calcular\_13](#fn_calcular_13)
    - [Descrição](#descrição-278)
  - [fn\_calcular\_horas\_extras](#fn_calcular_horas_extras)
    - [Descrição](#descrição-279)
  - [Functions Auditoria](#functions-auditoria)
  - [fn\_calcular\_score](#fn_calcular_score)
    - [Descrição](#descrição-280)
  - [fn\_calcular\_icb](#fn_calcular_icb)
    - [Descrição](#descrição-281)
  - [fn\_total\_erros](#fn_total_erros)
    - [Descrição](#descrição-282)
  - [fn\_total\_alertas](#fn_total_alertas)
    - [Descrição](#descrição-283)
  - [fn\_percentual\_documentacao](#fn_percentual_documentacao)
    - [Descrição](#descrição-284)
  - [Functions Governança](#functions-governança)
  - [fn\_versao\_atual](#fn_versao_atual)
    - [Descrição](#descrição-285)
  - [fn\_release\_atual](#fn_release_atual)
    - [Descrição](#descrição-286)
  - [fn\_total\_migracoes](#fn_total_migracoes)
    - [Descrição](#descrição-287)
  - [fn\_metadata\_objeto](#fn_metadata_objeto)
    - [Descrição](#descrição-288)
  - [Functions Segurança](#functions-segurança)
  - [fn\_hash\_senha](#fn_hash_senha)
    - [Descrição](#descrição-289)
  - [fn\_validar\_permissao](#fn_validar_permissao)
    - [Descrição](#descrição-290)
  - [fn\_usuario\_admin](#fn_usuario_admin)
    - [Descrição](#descrição-291)
  - [Functions LGPD](#functions-lgpd)
  - [fn\_anonimizar\_nome](#fn_anonimizar_nome)
    - [Descrição](#descrição-292)
  - [fn\_anonimizar\_email](#fn_anonimizar_email)
    - [Descrição](#descrição-293)
  - [fn\_mascarar\_documento](#fn_mascarar_documento)
    - [Descrição](#descrição-294)
  - [fn\_mascarar\_telefone](#fn_mascarar_telefone)
    - [Descrição](#descrição-295)
  - [Functions Sistema](#functions-sistema)
  - [fn\_health\_check](#fn_health_check)
    - [Descrição](#descrição-296)
  - [fn\_database\_size](#fn_database_size)
    - [Descrição](#descrição-297)
  - [fn\_schema\_size](#fn_schema_size)
    - [Descrição](#descrição-298)
  - [fn\_table\_size](#fn_table_size)
    - [Descrição](#descrição-299)
  - [fn\_index\_size](#fn_index_size)
    - [Descrição](#descrição-300)
    - [Boas Práticas](#boas-práticas-1)
    - [Dependências](#dependências-2)
  - [Estatísticas Previstas](#estatísticas-previstas-1)
  - [6.13 Triggers](#613-triggers)
    - [Objetivos](#objetivos-12)
    - [Convenções](#convenções-4)
    - [Estrutura da Documentação](#estrutura-da-documentação-2)
    - [Classificação](#classificação-2)
  - [Triggers de Auditoria](#triggers-de-auditoria)
  - [tg\_bi\_auditoria](#tg_bi_auditoria)
    - [Evento](#evento)
    - [Objetivo](#objetivo-9)
    - [Campos Atualizados](#campos-atualizados)
  - [tg\_bu\_auditoria](#tg_bu_auditoria)
    - [Evento](#evento-1)
    - [Objetivo](#objetivo-10)
    - [Campos Atualizados](#campos-atualizados-1)
  - [tg\_bd\_auditoria](#tg_bd_auditoria)
    - [Evento](#evento-2)
    - [Objetivo](#objetivo-11)
  - [tg\_ad\_log](#tg_ad_log)
    - [Evento](#evento-3)
    - [Objetivo](#objetivo-12)
  - [Triggers de Controle de Datas](#triggers-de-controle-de-datas)
  - [tg\_created\_at](#tg_created_at)
    - [Objetivo](#objetivo-13)
  - [tg\_updated\_at](#tg_updated_at)
    - [Objetivo](#objetivo-14)
  - [tg\_deleted\_at](#tg_deleted_at)
    - [Objetivo](#objetivo-15)
  - [Triggers de Controle de Versão](#triggers-de-controle-de-versão)
  - [tg\_incrementar\_versao](#tg_incrementar_versao)
    - [Objetivo](#objetivo-16)
  - [Triggers de Exclusão Lógica](#triggers-de-exclusão-lógica)
  - [tg\_soft\_delete](#tg_soft_delete)
    - [Objetivo](#objetivo-17)
    - [Campos](#campos-1)
  - [Triggers Financeiros](#triggers-financeiros)
  - [tg\_fluxo\_caixa](#tg_fluxo_caixa)
    - [Evento](#evento-4)
    - [Objetivo](#objetivo-18)
  - [tg\_contas\_receber](#tg_contas_receber)
    - [Objetivo](#objetivo-19)
  - [tg\_contas\_pagar](#tg_contas_pagar)
    - [Objetivo](#objetivo-20)
  - [tg\_recalcular\_saldo](#tg_recalcular_saldo)
    - [Objetivo](#objetivo-21)
  - [Triggers Comerciais](#triggers-comerciais)
  - [tg\_cliente\_status](#tg_cliente_status)
    - [Objetivo](#objetivo-22)
  - [tg\_venda\_total](#tg_venda_total)
    - [Objetivo](#objetivo-23)
  - [tg\_comissao](#tg_comissao)
    - [Objetivo](#objetivo-24)
  - [Triggers Fiscais](#triggers-fiscais)
  - [tg\_nota\_fiscal](#tg_nota_fiscal)
    - [Objetivo](#objetivo-25)
  - [tg\_impostos](#tg_impostos)
    - [Objetivo](#objetivo-26)
  - [Triggers Turismo](#triggers-turismo)
  - [tg\_reserva](#tg_reserva)
    - [Objetivo](#objetivo-27)
  - [tg\_pacote](#tg_pacote)
    - [Objetivo](#objetivo-28)
  - [tg\_voucher](#tg_voucher)
    - [Objetivo](#objetivo-29)
  - [Triggers Bike Tour](#triggers-bike-tour)
  - [tg\_inscricao](#tg_inscricao)
    - [Objetivo](#objetivo-30)
  - [tg\_checkin](#tg_checkin)
    - [Objetivo](#objetivo-31)
  - [tg\_classificacao](#tg_classificacao)
    - [Objetivo](#objetivo-32)
  - [Triggers Recursos Humanos](#triggers-recursos-humanos)
  - [tg\_ponto](#tg_ponto)
    - [Objetivo](#objetivo-33)
  - [tg\_folha](#tg_folha)
    - [Objetivo](#objetivo-34)
  - [Triggers Governança](#triggers-governança)
  - [tg\_metadata](#tg_metadata)
    - [Objetivo](#objetivo-35)
  - [tg\_release](#tg_release)
    - [Objetivo](#objetivo-36)
  - [tg\_migracao](#tg_migracao)
    - [Objetivo](#objetivo-37)
  - [Triggers Segurança](#triggers-segurança)
  - [tg\_log\_login](#tg_log_login)
    - [Objetivo](#objetivo-38)
  - [tg\_log\_permissao](#tg_log_permissao)
    - [Objetivo](#objetivo-39)
  - [tg\_log\_role](#tg_log_role)
    - [Objetivo](#objetivo-40)
  - [Triggers Sistema](#triggers-sistema)
  - [tg\_health\_check](#tg_health_check)
    - [Objetivo](#objetivo-41)
  - [tg\_dashboard](#tg_dashboard)
    - [Objetivo](#objetivo-42)
  - [tg\_cache](#tg_cache)
    - [Objetivo](#objetivo-43)
  - [Ordem de Execução](#ordem-de-execução)
  - [Padrões Obrigatórios](#padrões-obrigatórios)
    - [Dependências](#dependências-3)
    - [Estatísticas Previstas](#estatísticas-previstas-2)
    - [Benefícios](#benefícios-1)
  - [6.14 Índices (Indexes)](#614-índices-indexes)
    - [Objetivos](#objetivos-13)
    - [Convenções](#convenções-5)
  - [Tipos Utilizados](#tipos-utilizados)
  - [PRIMARY KEY](#primary-key)
  - [UNIQUE INDEX](#unique-index)
  - [FOREIGN KEY INDEX](#foreign-key-index)
  - [INDEX SIMPLES](#index-simples)
  - [ÍNDICE COMPOSTO](#índice-composto)
  - [ÍNDICE PARCIAL](#índice-parcial)
  - [ÍNDICE FUNCIONAL](#índice-funcional)
  - [GIN INDEX](#gin-index)
  - [GiST INDEX](#gist-index)
  - [BRIN INDEX](#brin-index)
  - [Estratégia de Indexação](#estratégia-de-indexação)
  - [Índices Obrigatórios](#índices-obrigatórios)
  - [Empresa](#empresa-1)
  - [Cliente](#cliente-1)
  - [Fornecedor](#fornecedor-1)
  - [Usuário](#usuário)
  - [Fluxo de Caixa](#fluxo-de-caixa)
  - [Contas a Receber](#contas-a-receber)
  - [Contas a Pagar](#contas-a-pagar)
  - [Reserva](#reserva-1)
  - [Pacote Turístico](#pacote-turístico)
  - [Evento Bike](#evento-bike)
  - [Índices Compostos](#índices-compostos)
  - [Índices Únicos](#índices-únicos)
  - [Índices Funcionais](#índices-funcionais)
  - [Índices Parciais](#índices-parciais)
  - [Índices JSONB](#índices-jsonb)
  - [Índices Geográficos](#índices-geográficos)
  - [Auditoria dos Índices](#auditoria-dos-índices)
  - [Indicadores Monitorados](#indicadores-monitorados)
    - [Boas Práticas](#boas-práticas-2)
    - [Estatísticas Previstas](#estatísticas-previstas-3)
    - [Benefícios](#benefícios-2)
  - [6.15 Chaves Estrangeiras (Foreign Keys)](#615-chaves-estrangeiras-foreign-keys)
    - [Objetivos](#objetivos-14)
    - [Convenções](#convenções-6)
    - [Estrutura da Documentação](#estrutura-da-documentação-3)
  - [Cardinalidades](#cardinalidades)
  - [Um para Um (1:1)](#um-para-um-11)
  - [Um para Muitos (1:N)](#um-para-muitos-1n)
  - [Muitos para Muitos (N:N)](#muitos-para-muitos-nn)
  - [Políticas de Integridade](#políticas-de-integridade)
  - [ON UPDATE](#on-update)
  - [ON DELETE](#on-delete)
    - [RESTRICT](#restrict)
    - [CASCADE](#cascade)
    - [SET NULL](#set-null)
    - [NO ACTION](#no-action)
  - [Relacionamentos Administrativos](#relacionamentos-administrativos)
    - [Empresa](#empresa-2)
    - [Usuário](#usuário-1)
  - [Relacionamentos Financeiros](#relacionamentos-financeiros)
    - [Plano de Contas](#plano-de-contas)
    - [Contas a Receber](#contas-a-receber-1)
    - [Contas a Pagar](#contas-a-pagar-1)
  - [Relacionamentos Comerciais](#relacionamentos-comerciais)
  - [Relacionamentos Fiscais](#relacionamentos-fiscais)
  - [Relacionamentos Turismo](#relacionamentos-turismo)
  - [Relacionamentos Bike Tour](#relacionamentos-bike-tour)
  - [Relacionamentos Recursos Humanos](#relacionamentos-recursos-humanos)
  - [Relacionamentos Auditoria](#relacionamentos-auditoria)
  - [Relacionamentos Governança](#relacionamentos-governança)
    - [Índices Obrigatórios](#índices-obrigatórios-1)
    - [Auditoria Automática](#auditoria-automática)
    - [Boas Práticas](#boas-práticas-3)
    - [Dependências](#dependências-4)
    - [Estatísticas Previstas](#estatísticas-previstas-4)
    - [Benefícios](#benefícios-3)
  - [Certificação](#certificação)
  - [6.16 Constraints](#616-constraints)
    - [Objetivos](#objetivos-15)
  - [Tipos de Constraints](#tipos-de-constraints)
    - [Convenções](#convenções-7)
  - [Primary Key](#primary-key-1)
  - [Foreign Key](#foreign-key)
  - [Unique](#unique)
  - [Check](#check)
  - [Default](#default)
  - [PRIMARY KEY](#primary-key-2)
  - [FOREIGN KEY](#foreign-key-1)
  - [UNIQUE](#unique-1)
  - [CHECK](#check-1)
  - [NOT NULL](#not-null)
  - [DEFAULT](#default-1)
  - [EXCLUDE](#exclude)
  - [Constraints Financeiras](#constraints-financeiras)
  - [Constraints Comerciais](#constraints-comerciais)
  - [Constraints Fiscais](#constraints-fiscais)
  - [Constraints Turismo](#constraints-turismo)
  - [Constraints Bike Tour](#constraints-bike-tour)
  - [Constraints Recursos Humanos](#constraints-recursos-humanos)
  - [Constraints Segurança](#constraints-segurança)
  - [Auditoria das Constraints](#auditoria-das-constraints)
    - [Dependências](#dependências-5)
    - [Boas Práticas](#boas-práticas-4)
    - [Estatísticas Previstas](#estatísticas-previstas-5)
  - [Critérios para Certificação](#critérios-para-certificação)
    - [Benefícios](#benefícios-4)
  - [6.17 Sequences](#617-sequences)
    - [Objetivos](#objetivos-16)
    - [Convenções](#convenções-8)
    - [Estrutura da Documentação](#estrutura-da-documentação-4)
  - [Configuração Padrão](#configuração-padrão)
  - [Exemplo](#exemplo)
  - [Associação com a Tabela](#associação-com-a-tabela)
  - [Sequences Administrativas](#sequences-administrativas)
  - [Sequences Financeiras](#sequences-financeiras)
  - [Sequences Comerciais](#sequences-comerciais)
  - [Sequences Fiscais](#sequences-fiscais)
  - [Sequences Turismo](#sequences-turismo)
  - [Sequences Bike Tour](#sequences-bike-tour)
  - [Sequences Recursos Humanos](#sequences-recursos-humanos)
  - [Sequences Auditoria](#sequences-auditoria)
  - [Sequences Governança](#sequences-governança)
  - [Estratégia de Crescimento](#estratégia-de-crescimento)
  - [Cache](#cache)
  - [Ciclo](#ciclo)
  - [Identity Columns](#identity-columns)
  - [Auditoria das Sequences](#auditoria-das-sequences)
    - [Boas Práticas](#boas-práticas-5)
    - [Dependências](#dependências-6)
    - [Estatísticas Previstas](#estatísticas-previstas-6)
    - [Critérios para Certificação](#critérios-para-certificação-1)
    - [Benefícios](#benefícios-5)
  - [6.18 Materialized Views](#618-materialized-views)
    - [Objetivos](#objetivos-17)
    - [Convenções](#convenções-9)
    - [Estrutura da Documentação](#estrutura-da-documentação-5)
  - [Estratégia de Atualização](#estratégia-de-atualização)
  - [Atualização](#atualização)
  - [Materialized Views Financeiras](#materialized-views-financeiras)
  - [mv\_fluxo\_caixa](#mv_fluxo_caixa)
    - [Objetivo](#objetivo-44)
    - [Atualização](#atualização-1)
    - [Origem](#origem-14)
  - [mv\_dre](#mv_dre)
    - [Objetivo](#objetivo-45)
  - [mv\_balancete](#mv_balancete)
    - [Objetivo](#objetivo-46)
  - [mv\_indicadores\_financeiros](#mv_indicadores_financeiros)
    - [Objetivo](#objetivo-47)
  - [Materialized Views Comerciais](#materialized-views-comerciais)
  - [mv\_vendas](#mv_vendas)
    - [Objetivo](#objetivo-48)
  - [mv\_clientes](#mv_clientes)
    - [Objetivo](#objetivo-49)
  - [mv\_ticket\_medio](#mv_ticket_medio)
    - [Objetivo](#objetivo-50)
  - [mv\_comissoes](#mv_comissoes)
    - [Objetivo](#objetivo-51)
  - [Materialized Views Fiscais](#materialized-views-fiscais)
  - [mv\_apuracao\_fiscal](#mv_apuracao_fiscal)
    - [Objetivo](#objetivo-52)
  - [mv\_notas\_emitidas](#mv_notas_emitidas)
    - [Objetivo](#objetivo-53)
  - [mv\_obrigacoes](#mv_obrigacoes)
    - [Objetivo](#objetivo-54)
  - [Materialized Views Turismo](#materialized-views-turismo)
  - [mv\_reservas](#mv_reservas)
    - [Objetivo](#objetivo-55)
  - [mv\_ocupacao](#mv_ocupacao)
    - [Objetivo](#objetivo-56)
  - [mv\_destinos](#mv_destinos)
    - [Objetivo](#objetivo-57)
  - [mv\_pacotes](#mv_pacotes)
    - [Objetivo](#objetivo-58)
  - [Materialized Views Bike Tour](#materialized-views-bike-tour)
  - [mv\_eventos](#mv_eventos)
    - [Objetivo](#objetivo-59)
  - [mv\_participantes](#mv_participantes)
    - [Objetivo](#objetivo-60)
  - [mv\_classificacao](#mv_classificacao)
    - [Objetivo](#objetivo-61)
  - [Materialized Views Recursos Humanos](#materialized-views-recursos-humanos)
  - [mv\_folha](#mv_folha)
    - [Objetivo](#objetivo-62)
  - [mv\_colaboradores](#mv_colaboradores)
    - [Objetivo](#objetivo-63)
  - [mv\_horas](#mv_horas)
    - [Objetivo](#objetivo-64)
  - [Materialized Views Auditoria](#materialized-views-auditoria)
  - [mv\_icb](#mv_icb)
    - [Objetivo](#objetivo-65)
  - [mv\_score](#mv_score)
    - [Objetivo](#objetivo-66)
  - [mv\_execucoes](#mv_execucoes)
    - [Objetivo](#objetivo-67)
  - [mv\_nao\_conformidades](#mv_nao_conformidades)
    - [Objetivo](#objetivo-68)
  - [Materialized Views Governança](#materialized-views-governança)
  - [mv\_release](#mv_release)
    - [Objetivo](#objetivo-69)
  - [mv\_metadata](#mv_metadata)
    - [Objetivo](#objetivo-70)
  - [mv\_migracoes](#mv_migracoes)
    - [Objetivo](#objetivo-71)
  - [Materialized Views Dashboard](#materialized-views-dashboard)
  - [mv\_dashboard\_executivo](#mv_dashboard_executivo)
    - [Objetivo](#objetivo-72)
  - [mv\_dashboard\_operacional](#mv_dashboard_operacional)
    - [Objetivo](#objetivo-73)
  - [mv\_dashboard\_financeiro](#mv_dashboard_financeiro)
    - [Objetivo](#objetivo-74)
  - [mv\_dashboard\_comercial](#mv_dashboard_comercial)
    - [Objetivo](#objetivo-75)
  - [mv\_dashboard\_turismo](#mv_dashboard_turismo)
    - [Objetivo](#objetivo-76)
  - [mv\_dashboard\_bike](#mv_dashboard_bike)
    - [Objetivo](#objetivo-77)
  - [Índices](#índices-8)
  - [Auditoria](#auditoria)
    - [Boas Práticas](#boas-práticas-6)
    - [Dependências](#dependências-7)
  - [Frequência Recomendada](#frequência-recomendada)
    - [Estatísticas Previstas](#estatísticas-previstas-7)
    - [Critérios para Certificação](#critérios-para-certificação-2)
    - [Benefícios](#benefícios-6)
  - [6.19 Domínios (Domains) e Tipos Personalizados (Custom Types)](#619-domínios-domains-e-tipos-personalizados-custom-types)
    - [Objetivos](#objetivos-18)
    - [Tipos Utilizados](#tipos-utilizados-1)
    - [Convenções](#convenções-10)
    - [Estrutura da Documentação](#estrutura-da-documentação-6)
  - [Domains Gerais](#domains-gerais)
  - [dm\_nome](#dm_nome)
  - [dm\_descricao](#dm_descricao)
  - [dm\_observacao](#dm_observacao)
  - [Domains Financeiros](#domains-financeiros)
  - [dm\_valor](#dm_valor)
  - [dm\_percentual](#dm_percentual)
  - [dm\_taxa](#dm_taxa)
  - [dm\_quantidade](#dm_quantidade)
  - [Domains de Datas](#domains-de-datas)
  - [dm\_data](#dm_data)
  - [dm\_datetime](#dm_datetime)
  - [dm\_ano](#dm_ano)
  - [dm\_mes](#dm_mes)
  - [Domains de Documentos](#domains-de-documentos)
  - [dm\_cpf](#dm_cpf)
  - [dm\_cnpj](#dm_cnpj)
  - [dm\_ie](#dm_ie)
  - [dm\_passaporte](#dm_passaporte)
  - [Domains de Contato](#domains-de-contato)
  - [dm\_email](#dm_email)
  - [dm\_telefone](#dm_telefone)
  - [dm\_cep](#dm_cep)
  - [Domains de Auditoria](#domains-de-auditoria)
  - [dm\_usuario](#dm_usuario)
  - [dm\_created\_at](#dm_created_at)
  - [dm\_updated\_at](#dm_updated_at)
  - [dm\_deleted\_at](#dm_deleted_at)
  - [dm\_versao](#dm_versao)
  - [ENUM Types](#enum-types)
  - [tp\_status](#tp_status)
  - [tp\_pagamento](#tp_pagamento)
  - [tp\_documento](#tp_documento)
  - [tp\_sexo](#tp_sexo)
  - [tp\_sim\_nao](#tp_sim_nao)
  - [tp\_tipo\_cliente](#tp_tipo_cliente)
  - [tp\_tipo\_empresa](#tp_tipo_empresa)
  - [Composite Types](#composite-types)
  - [Arrays](#arrays)
  - [JSONB](#jsonb)
    - [Auditoria](#auditoria-1)
    - [Boas Práticas](#boas-práticas-7)
    - [Dependências](#dependências-8)
    - [Estatísticas Previstas](#estatísticas-previstas-8)
    - [Critérios para Certificação](#critérios-para-certificação-3)
    - [Benefícios](#benefícios-7)
  - [6.20 Extensões PostgreSQL (Extensions)](#620-extensões-postgresql-extensions)
    - [Objetivos](#objetivos-19)
  - [Política de Utilização](#política-de-utilização)
    - [Estrutura da Documentação](#estrutura-da-documentação-7)
  - [Extensões Obrigatórias](#extensões-obrigatórias)
  - [pgcrypto](#pgcrypto)
  - [uuid-ossp](#uuid-ossp)
  - [unaccent](#unaccent)
  - [pg\_trgm](#pg_trgm)
  - [btree\_gin](#btree_gin)
  - [btree\_gist](#btree_gist)
  - [pg\_stat\_statements](#pg_stat_statements)
  - [tablefunc](#tablefunc)
  - [fuzzystrmatch](#fuzzystrmatch)
  - [hstore](#hstore)
  - [cube](#cube)
  - [earthdistance](#earthdistance)
  - [postgres\_fdw](#postgres_fdw)
  - [Extensões Futuras](#extensões-futuras)
  - [PostGIS](#postgis)
  - [pgRouting](#pgrouting)
  - [timescaledb](#timescaledb)
  - [Extensões Não Permitidas](#extensões-não-permitidas)
  - [Instalação](#instalação)
    - [Auditoria](#auditoria-2)
    - [Boas Práticas](#boas-práticas-8)
    - [Dependências](#dependências-9)
    - [Estatísticas Previstas](#estatísticas-previstas-9)
    - [Critérios para Certificação](#critérios-para-certificação-4)
    - [Benefícios](#benefícios-8)
  - [6.21 Performance e Otimização](#621-performance-e-otimização)
    - [Objetivos](#objetivos-20)
  - [Áreas Monitoradas](#áreas-monitoradas)
  - [Estratégia de Otimização](#estratégia-de-otimização)
  - [Estatísticas (ANALYZE)](#estatísticas-analyze)
  - [VACUUM](#vacuum)
  - [VACUUM ANALYZE](#vacuum-analyze)
  - [VACUUM FULL](#vacuum-full)
  - [REINDEX](#reindex)
  - [CLUSTER](#cluster)
  - [EXPLAIN](#explain)
  - [EXPLAIN ANALYZE](#explain-analyze)
    - [Índices](#índices-9)
  - [Consultas Lentas](#consultas-lentas)
    - [pg\_stat\_statements](#pg_stat_statements-1)
    - [Cache](#cache-1)
  - [Memória](#memória)
  - [Configurações Recomendadas](#configurações-recomendadas)
  - [shared\_buffers](#shared_buffers)
  - [effective\_cache\_size](#effective_cache_size)
  - [work\_mem](#work_mem)
  - [maintenance\_work\_mem](#maintenance_work_mem)
  - [wal\_buffers](#wal_buffers)
  - [Paralelismo](#paralelismo)
  - [Particionamento](#particionamento)
  - [Compressão](#compressão)
  - [Conexões](#conexões)
  - [Locks](#locks)
  - [KPI de Performance](#kpi-de-performance)
    - [Auditoria](#auditoria-3)
  - [Ferramentas Utilizadas](#ferramentas-utilizadas)
    - [Boas Práticas](#boas-práticas-9)
  - [Integração com o Framework DBA](#integração-com-o-framework-dba)
  - [Critérios para Certificação](#critérios-para-certificação-5)
  - [Benefícios](#benefícios-9)
  - [6.22 Backup, Recuperação e Continuidade de Negócios](#622-backup-recuperação-e-continuidade-de-negócios)
    - [Objetivos](#objetivos-21)
  - [Estratégia de Backup](#estratégia-de-backup)
  - [Tipos de Backup](#tipos-de-backup)
    - [Backup Completo](#backup-completo)
    - [Backup Incremental](#backup-incremental)
    - [Backup Diferencial](#backup-diferencial)
    - [Backup Lógico](#backup-lógico)
    - [Backup Físico](#backup-físico)
  - [WAL Archiving](#wal-archiving)
  - [Point-in-Time Recovery (PITR)](#point-in-time-recovery-pitr)
  - [Frequência](#frequência)
  - [Retenção](#retenção)
  - [Armazenamento](#armazenamento)
  - [Criptografia](#criptografia)
  - [Compactação](#compactação)
  - [Validação](#validação)
  - [Testes de Recuperação](#testes-de-recuperação)
  - [Recovery Time Objective (RTO)](#recovery-time-objective-rto)
  - [Recovery Point Objective (RPO)](#recovery-point-objective-rpo)
  - [Disaster Recovery (DR)](#disaster-recovery-dr)
  - [Alta Disponibilidade](#alta-disponibilidade)
  - [Monitoramento](#monitoramento)
    - [Auditoria](#auditoria-4)
  - [Indicadores](#indicadores-29)
    - [Boas Práticas](#boas-práticas-10)
    - [Integração com o Framework DBA](#integração-com-o-framework-dba-1)
    - [Critérios para Certificação](#critérios-para-certificação-6)
    - [Benefícios](#benefícios-10)
  - [6.23 Monitoramento e Observabilidade](#623-monitoramento-e-observabilidade)
    - [Objetivos](#objetivos-22)
  - [Escopo](#escopo)
  - [Componentes Monitorados](#componentes-monitorados)
  - [Banco de Dados](#banco-de-dados)
  - [Sistema Operacional](#sistema-operacional)
  - [Infraestrutura](#infraestrutura)
  - [Métricas Coletadas](#métricas-coletadas)
    - [Disponibilidade](#disponibilidade)
    - [CPU](#cpu)
    - [Memória](#memória-1)
    - [Disco](#disco)
    - [Banco de Dados](#banco-de-dados-1)
  - [Monitoramento de Consultas](#monitoramento-de-consultas)
  - [Monitoramento de Locks](#monitoramento-de-locks)
  - [Logs](#logs)
  - [Alertas Automáticos](#alertas-automáticos)
  - [Ferramentas Homologadas](#ferramentas-homologadas)
  - [Dashboard Técnico](#dashboard-técnico)
  - [Health Check](#health-check)
  - [Indicadores (KPIs)](#indicadores-kpis)
  - [Eventos Monitorados](#eventos-monitorados)
    - [Auditoria](#auditoria-5)
    - [Boas Práticas](#boas-práticas-11)
    - [Integração com o Framework DBA](#integração-com-o-framework-dba-2)
    - [Critérios para Certificação](#critérios-para-certificação-7)
    - [Benefícios](#benefícios-11)
  - [6.24 Segurança do Banco de Dados](#624-segurança-do-banco-de-dados)
    - [Objetivos](#objetivos-23)
  - [Princípios](#princípios)
  - [Classificação das Informações](#classificação-das-informações)
  - [Controle de Acesso](#controle-de-acesso)
  - [Roles Corporativas](#roles-corporativas)
  - [Política de Permissões](#política-de-permissões)
  - [Autenticação](#autenticação)
  - [Criptografia](#criptografia-1)
  - [Conexões Seguras](#conexões-seguras)
  - [Dados Sensíveis](#dados-sensíveis)
  - [Mascaramento de Dados](#mascaramento-de-dados)
  - [LGPD](#lgpd)
  - [Row Level Security (RLS)](#row-level-security-rls)
    - [Auditoria](#auditoria-6)
  - [Logs](#logs-1)
  - [Políticas de Senha](#políticas-de-senha)
  - [Bloqueio de Conta](#bloqueio-de-conta)
  - [Backup Seguro](#backup-seguro)
  - [Monitoramento](#monitoramento-1)
  - [Auditoria Automática](#auditoria-automática-1)
  - [Indicadores de Segurança](#indicadores-de-segurança)
  - [Ferramentas](#ferramentas)
    - [Integração com o Framework DBA](#integração-com-o-framework-dba-3)
    - [Critérios para Certificação](#critérios-para-certificação-8)
    - [Benefícios](#benefícios-12)
  - [6.25 Framework DBA e Certificação Técnica](#625-framework-dba-e-certificação-técnica)
    - [Objetivos](#objetivos-24)
  - [Componentes do Framework](#componentes-do-framework)
  - [Arquitetura do Framework](#arquitetura-do-framework)
  - [Auditorias Executadas](#auditorias-executadas)
  - [Health Check](#health-check-1)
  - [Índice de Conformidade do Banco (ICB)](#índice-de-conformidade-do-banco-icb-1)
  - [Critérios Avaliados](#critérios-avaliados)
  - [Pesos](#pesos)
  - [Plano Automático de Correção](#plano-automático-de-correção)
  - [Classificação das Não Conformidades](#classificação-das-não-conformidades)
  - [Dashboard Técnico](#dashboard-técnico-1)
  - [Dashboard Executivo](#dashboard-executivo)
  - [Indicadores (KPIs)](#indicadores-kpis-1)
  - [Frequência das Auditorias](#frequência-das-auditorias)
  - [Certificação Técnica](#certificação-técnica)
  - [Níveis de Maturidade](#níveis-de-maturidade)
  - [Integração](#integração)
  - [Benefícios](#benefícios-13)
  - [Critérios para Certificação Final](#critérios-para-certificação-final)
  - [6.26 Glossário Técnico](#626-glossário-técnico)
    - [Objetivos](#objetivos-25)
  - [Termos Gerais](#termos-gerais)
  - [API](#api)
  - [Banco de Dados](#banco-de-dados-2)
  - [PostgreSQL](#postgresql)
  - [Schema](#schema)
  - [Tabela](#tabela)
  - [Coluna](#coluna)
  - [Registro](#registro)
- [Objetos do Banco](#objetos-do-banco)
  - [Primary Key (PK)](#primary-key-pk)
  - [Foreign Key (FK)](#foreign-key-fk)
  - [Constraint](#constraint)
  - [Sequence](#sequence)
  - [Trigger](#trigger)
  - [Function](#function)
  - [Procedure](#procedure)
  - [View](#view)
  - [Materialized View](#materialized-view)
  - [Index](#index)
- [Segurança](#segurança)
  - [Role](#role)
  - [Permission](#permission)
  - [RLS](#rls)
  - [LGPD](#lgpd-1)
  - [Criptografia](#criptografia-2)
  - [TLS](#tls)
- [Performance](#performance)
  - [VACUUM](#vacuum-1)
  - [ANALYZE](#analyze)
  - [EXPLAIN](#explain-1)
  - [EXPLAIN ANALYZE](#explain-analyze-1)
  - [Cache Hit Ratio](#cache-hit-ratio)
  - [Deadlock](#deadlock)
- [Backup](#backup)
  - [Backup Full](#backup-full)
  - [Backup Incremental](#backup-incremental-1)
  - [PITR](#pitr)
  - [WAL](#wal)
  - [Restore](#restore)
  - [Framework DBA](#framework-dba)
  - [Health Check](#health-check-2)
  - [ICB](#icb)
  - [Score Técnico](#score-técnico)
  - [Plano Automático de Correção](#plano-automático-de-correção-1)
  - [Certificação Técnica](#certificação-técnica-1)
  - [Desenvolvimento](#desenvolvimento)
  - [Clean Code](#clean-code)
  - [SOLID](#solid)
  - [DDD](#ddd)
  - [SemVer](#semver)
  - [Git](#git)
  - [GitHub](#github)
  - [Business Intelligence](#business-intelligence)
  - [Dashboard](#dashboard)
  - [KPI](#kpi)
  - [ETL](#etl)
  - [Turismo](#turismo)
  - [Pacote Turístico](#pacote-turístico-1)
  - [Reserva](#reserva-2)
  - [Bike Tour](#bike-tour)
  - [Convenções](#convenções-11)
  - [Benefícios](#benefícios-14)
  - [6.27 Referências Técnicas](#627-referências-técnicas)
  - [Objetivos](#objetivos-26)
  - [Banco de Dados](#banco-de-dados-3)
  - [PostgreSQL](#postgresql-1)
  - [SQL](#sql)
  - [ISO/IEC 9075](#isoiec-9075)
  - [Segurança](#segurança-1)
  - [ISO/IEC 27001](#isoiec-27001)
  - [ISO/IEC 27002](#isoiec-27002)
  - [OWASP](#owasp)
  - [CIS PostgreSQL Benchmark](#cis-postgresql-benchmark)
  - [Governança](#governança)
  - [COBIT](#cobit)
  - [ITIL](#itil)
  - [Desenvolvimento](#desenvolvimento-1)
  - [Clean Architecture](#clean-architecture)
  - [Clean Code](#clean-code-1)
  - [SOLID](#solid-1)
  - [Domain Driven Design (DDD)](#domain-driven-design-ddd)
  - [Versionamento](#versionamento)
  - [Semantic Versioning](#semantic-versioning)
  - [Keep a Changelog](#keep-a-changelog)
  - [Git](#git-1)
  - [GitHub](#github-1)
  - [Python](#python)
  - [PEP](#pep)
  - [FastAPI](#fastapi)
  - [SQLAlchemy](#sqlalchemy)
  - [Alembic](#alembic)
  - [React](#react)
  - [TypeScript](#typescript)
  - [Flutter](#flutter)
  - [Microsoft Power BI](#microsoft-power-bi)
  - [LGPD](#lgpd-2)
  - [Convenções Utilizadas](#convenções-utilizadas)
  - [Compatibilidade](#compatibilidade)
  - [Atualização das Referências](#atualização-das-referências)
  - [Benefícios](#benefícios-15)
  - [Apêndice A — Convenções de Nomenclatura](#apêndice-a--convenções-de-nomenclatura)
  - [Objetivos](#objetivos-27)
  - [Regras Gerais](#regras-gerais)
  - [Banco de Dados](#banco-de-dados-4)
    - [Nome do Banco](#nome-do-banco)
    - [Schemas](#schemas)
    - [Tabelas](#tabelas)
    - [Colunas](#colunas-11)
    - [Chaves Primárias](#chaves-primárias-1)
    - [Chaves Estrangeiras](#chaves-estrangeiras)
    - [Constraints](#constraints)
  - [Primary Key](#primary-key-3)
  - [Foreign Key](#foreign-key-2)
  - [Unique](#unique-2)
  - [Check](#check-2)
  - [Índices](#índices-10)
  - [Sequences](#sequences)
  - [Views](#views)
  - [Materialized Views](#materialized-views)
  - [Procedures](#procedures)
  - [Functions](#functions)
  - [Triggers](#triggers)
  - [Tipos Personalizados](#tipos-personalizados)
  - [Domains](#domains)
- [APIs](#apis)
  - [Classes Python](#classes-python)
  - [Métodos Python](#métodos-python)
  - [Variáveis Python](#variáveis-python)
  - [Constantes](#constantes)
  - [Arquivos SQL](#arquivos-sql)
  - [Arquivos Markdown](#arquivos-markdown)
  - [Branches Git](#branches-git)
  - [Commits](#commits)
  - [Versionamento](#versionamento-1)
  - [Benefícios](#benefícios-16)
  - [Apêndice B — Checklist de Conformidade](#apêndice-b--checklist-de-conformidade)
  - [Objetivos](#objetivos-28)
  - [Estrutura do Checklist](#estrutura-do-checklist)
  - [1. Estrutura do Banco](#1-estrutura-do-banco)
  - [2. Tabelas](#2-tabelas)
  - [3. Colunas](#3-colunas)
  - [4. Chaves Primárias](#4-chaves-primárias)
  - [5. Chaves Estrangeiras](#5-chaves-estrangeiras)
  - [6. Índices](#6-índices)
  - [7. Constraints](#7-constraints)
  - [8. Sequences](#8-sequences)
  - [9. Views](#9-views)
  - [10. Materialized Views](#10-materialized-views)
  - [11. Procedures](#11-procedures)
  - [12. Functions](#12-functions)
  - [13. Triggers](#13-triggers)
  - [14. Segurança](#14-segurança)
  - [15. Performance](#15-performance)
  - [16. Backup](#16-backup)
  - [17. Monitoramento](#17-monitoramento)
  - [18. Documentação](#18-documentação)
  - [19. Governança](#19-governança)
  - [20. Certificação Técnica](#20-certificação-técnica)
  - [Resultado Final](#resultado-final)
  - [Benefícios](#benefícios-17)
  - [Apêndice C — Estatísticas Consolidadas do Banco de Dados](#apêndice-c--estatísticas-consolidadas-do-banco-de-dados)
  - [Objetivos](#objetivos-29)
  - [Visão Geral](#visão-geral-7)
  - [Estrutura Geral](#estrutura-geral)
  - [Estatísticas das Tabelas](#estatísticas-das-tabelas)
  - [Exemplo](#exemplo-1)
  - [Estatísticas de Colunas](#estatísticas-de-colunas)
  - [Estatísticas de Índices](#estatísticas-de-índices)
  - [Indicadores](#indicadores-30)
  - [Estatísticas de Constraints](#estatísticas-de-constraints)
  - [Exemplo](#exemplo-2)
  - [Estatísticas de Relacionamentos](#estatísticas-de-relacionamentos)
  - [Estatísticas de Views](#estatísticas-de-views)
  - [Estatísticas de Procedures](#estatísticas-de-procedures)
  - [Estatísticas de Functions](#estatísticas-de-functions)
  - [Estatísticas de Triggers](#estatísticas-de-triggers)
  - [Estatísticas de Auditoria](#estatísticas-de-auditoria)
  - [Estatísticas de Segurança](#estatísticas-de-segurança)
  - [Estatísticas de Backup](#estatísticas-de-backup)
  - [Estatísticas de Performance](#estatísticas-de-performance)
  - [Estatísticas de Crescimento](#estatísticas-de-crescimento)
  - [Indicadores Técnicos](#indicadores-técnicos-1)
  - [Índice de Conformidade do Banco (ICB)](#índice-de-conformidade-do-banco-icb-2)
  - [Score Técnico](#score-técnico-1)
  - [Atualização das Estatísticas](#atualização-das-estatísticas)
  - [Fontes das Informações](#fontes-das-informações)
  - [Benefícios](#benefícios-18)
  - [Apêndice D — Matriz de Rastreabilidade](#apêndice-d--matriz-de-rastreabilidade)
  - [Objetivos](#objetivos-30)
  - [Estrutura da Matriz](#estrutura-da-matriz)
  - [Identificação dos Requisitos](#identificação-dos-requisitos)
  - [Estrutura dos Módulos](#estrutura-dos-módulos)
  - [Matriz de Rastreabilidade](#matriz-de-rastreabilidade)
  - [Rastreabilidade das Tabelas](#rastreabilidade-das-tabelas)
  - [Exemplo](#exemplo-3)
  - [Rastreabilidade das APIs](#rastreabilidade-das-apis)
  - [Exemplo](#exemplo-4)
  - [Rastreabilidade das Auditorias](#rastreabilidade-das-auditorias)
  - [Integração com o Framework DBA](#integração-com-o-framework-dba-4)
  - [Controle de Mudanças](#controle-de-mudanças)
  - [Benefícios](#benefícios-19)
  - [Apêndice E — Estrutura Completa do Framework DBA](#apêndice-e--estrutura-completa-do-framework-dba)
  - [Objetivos](#objetivos-31)
  - [Arquitetura Geral](#arquitetura-geral)
  - [Estrutura de Diretórios](#estrutura-de-diretórios)
  - [CORE](#core)
  - [Auditorias](#auditorias)
  - [Documentação](#documentação)
  - [Performance](#performance-1)
  - [Segurança](#segurança-2)
  - [Backup](#backup-1)
  - [Monitoramento](#monitoramento-2)
  - [Governança](#governança-1)
  - [Certificação](#certificação-1)
  - [Dashboard Técnico](#dashboard-técnico-2)
  - [Dashboard Executivo](#dashboard-executivo-1)
  - [Fluxo de Execução](#fluxo-de-execução)
  - [Fluxo da Certificação](#fluxo-da-certificação)
  - [Integração com o ERP](#integração-com-o-erp)
  - [Integração com CI/CD](#integração-com-cicd)
  - [Cronograma de Execução](#cronograma-de-execução)
  - [Indicadores](#indicadores-31)
  - [Evolução do Framework](#evolução-do-framework)
  - [Versão 1](#versão-1)
  - [Versão 2](#versão-2)
  - [Versão 3](#versão-3)
  - [Benefícios](#benefícios-20)
  - [Encerramento](#encerramento)

---

## 1. Visão Geral

O Dicionário de Dados documenta todos os objetos existentes no banco de dados do **WMA Travel ERP**.

Seu objetivo é padronizar o entendimento da estrutura física e lógica do banco de dados,
servindo como referência técnica para desenvolvedores, DBAs, analistas de sistemas,
arquitetos de software e equipes de auditoria.

---

## 2. Objetivos

Este documento possui os seguintes objetivos:

- Documentar todas as tabelas.
- Documentar todas as colunas.
- Documentar relacionamentos.
- Documentar tipos de dados.
- Documentar regras de negócio.
- Facilitar manutenção.
- Padronizar nomenclatura.
- Apoiar auditorias.

---

## 3. Escopo

O documento contempla:

- Tabelas
- Views
- Procedures
- Functions
- Triggers
- Índices
- Constraints
- Foreign Keys
- Comentários Técnicos

---

## 4. Convenções

## Nomenclatura

Todas as tabelas utilizam:

```text
snake_case
```

Exemplo:

```text
cliente

empresa

usuario

lancamento_financeiro
```

---

## Chaves Primárias

Formato:

```text
id_<tabela>
```

Exemplos:

```text
id_cliente

id_empresa

id_usuario
```

---

## Colunas de Auditoria

Todas as tabelas corporativas possuem:

| Coluna     | Tipo      |
| ---------- |
| created_at | timestamp |
| updated_at | timestamp |
| deleted_at | timestamp |
| created_by | integer   |
| updated_by | integer   |
| deleted_by | integer   |
| versao     | integer   |

---

## 5. Estrutura Geral

O banco está organizado em aproximadamente:

|       Objeto | Quantidade |
| -----------: |
|      Tabelas | 190        |
|        Views | 25+        |
|   Procedures | 40+        |
|    Functions | 80+        |
|     Triggers | 60+        |
| Foreign Keys | 142+       |
|      Índices | 500+       |

---

## 6. Dicionário das Tabelas

---

## 6.1 Módulo Administrativo

O módulo **Administrativo** concentra as entidades responsáveis pela configuração geral
do sistema, autenticação de usuários, gerenciamento de perfis de acesso, controle de
permissões e manutenção dos parâmetros globais do ERP.

---

## empresa

### Descrição

Armazena as informações cadastrais das empresas administradas pelo ERP.

### Finalidade

Representa a entidade central do sistema, responsável pelo cadastro principal da
organização. Todas as demais entidades corporativas possuem relacionamento direto
ou indireto com esta tabela, garantindo a integração e a consistência dos dados
entre os módulos do ERP.

### Chave Primária

| Coluna     |
| ---------- |
| id_empresa |

### Relacionamentos

| Tabela           | Cardinalidade |
| ---------------- |
| usuário          | 1:N           |
| cliente          | 1:N           |
| fornecedor       | 1:N           |
| conta_financeira | 1:N           |
| plano_conta      | 1:N           |

### Colunas

| Coluna              | Tipo         | Nulo | Descrição                            |
| ------------------- | ------------ | ---- |
| id_empresa          | bigint       | Não  | Identificador único da empresa       |
| razao_social        | varchar(255) | Não  | Razão social                         |
| nome_fantasia       | varchar(255) | Sim  | Nome fantasia                        |
| cnpj                | varchar(18)  | Não  | Cadastro Nacional da Pessoa Jurídica |
| inscricao_estadual  | varchar(30)  | Sim  | Inscrição estadual                   |
| inscricao_municipal | varchar(30)  | Sim  | Inscrição municipal                  |
| email               | varchar(255) | Sim  | E-mail principal                     |
| telefone            | varchar(30)  | Sim  | Telefone                             |
| site                | varchar(255) | Sim  | Website                              |
| created_at          | timestamp    | Não  | Data de criação                      |
| updated_at          | timestamp    | Não  | Última alteração                     |
| deleted_at          | timestamp    | Sim  | Exclusão lógica                      |
| created_by          | integer      | Sim  | Usuário criador                      |
| updated_by          | integer      | Sim  | Usuário responsável pela alteração   |
| deleted_by          | integer      | Sim  | Usuário responsável pela exclusão    |
| versao              | integer      | Não  | Controle de versão                   |

### Índices

| Índice                   | Tipo        |
| ------------------------ |
| pk_empresa               | Primary Key |
| uk_empresa_cnpj          | Unique      |
| idx_empresa_razao_social | B-tree      |

### Observações

- Tabela raiz do ERP.
- Não permite exclusão física.
- Utiliza auditoria completa.

---

## usuario

### Descrição

Armazena os usuários do sistema.

### Finalidade

Controlar autenticação, autorização e auditoria.

### Chave Primária

| Coluna     |
| ---------- |
| id_usuario |

### Relacionamentos

| Tabela     | Cardinalidade |
| ---------- | ------------- |
| empresa    | N:1           |
| perfil     | N:1           |
| log_acesso | 1:N           |

### Colunas

| Coluna       | Tipo         | Nulo | Descrição           |
| ------------ | ------------ | ---- |
| id_usuario   | bigint       | Não  | Identificador       |
| id_empresa   | bigint       | Não  | Empresa             |
| id_perfil    | bigint       | Não  | Perfil de acesso    |
| nome         | varchar(150) | Não  | Nome completo       |
| email        | varchar(255) | Não  | Login               |
| senha_hash   | varchar(255) | Não  | Senha criptografada |
| ativo        | boolean      | Não  | Situação            |
| ultimo_login | timestamp    | Sim  | Último acesso       |
| created_at   | timestamp    | Não  | Data de criação     |
| updated_at   | timestamp    | Não  | Última alteração    |
| deleted_at   | timestamp    | Sim  | Exclusão lógica     |
| created_by   | integer      | Sim  | Usuário criador     |
| updated_by   | integer      | Sim  | Usuário alteração   |
| deleted_by   | integer      | Sim  | Usuário exclusão    |
| versao       | integer      | Não  | Controle de versão  |

### Índices

| Índice              | Tipo        |
| ------------------- |
| pk_usuario          | Primary Key |
| uk_usuario_email    | Unique      |
| idx_usuario_empresa | B-tree      |
| idx_usuario_perfil  | B-tree      |

### Observações

- Senhas nunca são armazenadas em texto.
- Autenticação via JWT.
- Suporte à autenticação multifator (planejado).

---

## perfil

### Descrição

Define os perfis de acesso do ERP.

### Finalidade

Implementar o controle de acesso baseado em papéis (RBAC).

### Chave Primária

| Coluna    |
| --------- |
| id_perfil |

### Colunas

| Coluna     | Tipo         | Nulo | Descrição          |
| ---------- | ------------ | ---- | ------------------ |
| id_perfil  | bigint       | Não  | Identificador      |
| nome       | varchar(100) | Não  | Nome do perfil     |
| descricao  | text         | Sim  | Descrição          |
| ativo      | boolean      | Não  | Situação           |
| created_at | timestamp    | Não  | Criação            |
| updated_at | timestamp    | Não  | Alteração          |
| deleted_at | timestamp    | Sim  | Exclusão lógica    |
| created_by | integer      | Sim  | Criador            |
| updated_by | integer      | Sim  | Alteração          |
| deleted_by | integer      | Sim  | Exclusão           |
| versao     | integer      | Não  | Controle de versão |

### Perfis previstos

- Administrador
- Diretor
- Financeiro
- Comercial
- Operacional
- Turismo
- Bike Tour
- Auditor
- DBA

---

## permissao

### Descrição

Armazena todas as permissões disponíveis no sistema.

### Finalidade

Permitir granularidade de acesso aos recursos do ERP.

### Colunas principais

| Coluna       | Tipo         |
| ------------ | ------------ |
| id_permissao | bigint       |
| codigo       | varchar(100) |
| descricao    | varchar(255) |
| modulo       | varchar(100) |
| ativo        | boolean      |
| versao       | integer      |

---

## perfil_permissao

### Descrição

Relaciona perfis às permissões.

### Tipo

Tabela de associação (N:N).

### Relacionamentos

| Origem | Destino   |
| ------ | --------- |
| perfil | permissao |

### Chave composta

- id_perfil
- id_permissao

---

## parametro_sistema

### Descrição

Armazena parâmetros globais do ERP.

### Exemplos

- Nome da empresa
- Time Zone
- Idioma
- Máscaras
- Configurações fiscais
- Configurações financeiras

---

## log_acesso

### Descrição

Registra todos os acessos ao sistema.

### Informações registradas

- Usuário
- Data
- Hora
- IP
- Navegador
- Sistema Operacional
- Token
- Resultado da autenticação

---

## log_operacao

### Descrição

Registra operações realizadas pelos usuários.

### Eventos

- Inclusão
- Alteração
- Exclusão
- Login
- Logout
- Exportação
- Importação

---

## configuracao

### Descrição

Armazena configurações técnicas utilizadas pelo sistema.

### Exemplos

- SMTP
- API
- Backup
- Logs
- Integrações
- Cache
- Segurança

---

## 6.2 Módulo Financeiro

O módulo Financeiro é responsável pelo controle econômico, financeiro, contábil e gerencial do ERP.

Todas as movimentações financeiras do sistema convergem para este módulo.

---

## grupo_conta

### Descrição

Representa o primeiro nível do Plano de Contas.

### Finalidade

Organizar todas as contas contábeis do ERP em grandes grupos.

### Exemplos

- Ativo
- Passivo
- Patrimônio Líquido
- Receitas
- Custos
- Despesas

### Chave Primária

| Coluna   |
| -------- |
| id_grupo |

### Colunas

| Coluna     | Tipo         | Nulo | Descrição           |
| ---------- | ------------ | ---- | ------------------- |
| id_grupo   | smallint     | Não  | Identificador       |
| codigo     | varchar(10)  | Não  | Código              |
| descricao  | varchar(150) | Não  | Nome do grupo       |
| natureza   | varchar(30)  | Não  | Natureza financeira |
| ativo      | boolean      | Não  | Situação            |
| created_at | timestamp    | Não  | Auditoria           |
| updated_at | timestamp    | Não  | Auditoria           |
| deleted_at | timestamp    | Sim  | Auditoria           |
| created_by | integer      | Sim  | Auditoria           |
| updated_by | integer      | Sim  | Auditoria           |
| deleted_by | integer      | Sim  | Auditoria           |
| versao     | integer      | Não  | Controle de versão  |

### Relacionamentos

- categoria_conta (1:N)

---

## categoria_conta

### Descrição

Segundo nível do Plano de Contas.

### Relacionamentos

Grupo → Categoria

### Exemplos

- Ativo Circulante
- Ativo Não Circulante
- Passivo Circulante
- Receitas Operacionais

### Chave Primária

id_categoria

### Foreign Keys

id_grupo

---

## subcategoria_conta

### Descrição

Terceiro nível do Plano de Contas.

### Objetivo

Detalhar as categorias financeiras.

### Exemplos

Ativo Circulante

↓

Banco

↓

Conta Corrente

---

## classificacao_conta

### Descrição

Quarto nível do Plano de Contas.

### Exemplos

Banco

Caixa

Aplicações Financeiras

Clientes

Fornecedores

Impostos

---

## plano_conta

### Descrição

Representa a menor unidade do Plano de Contas.

Cada lançamento financeiro utiliza exatamente uma conta deste cadastro.

### Estrutura

Grupo

↓

Categoria

↓

Subcategoria

↓

Classificação

↓

Conta

### Colunas

| Coluna            | Tipo         |
| ----------------- | ------------ |
| id_plano_conta    | bigint       |
| codigo            | varchar(30)  |
| descricao         | varchar(255) |
| natureza          | varchar(20)  |
| aceita_lancamento | boolean      |
| ativo             | boolean      |
| versao            | integer      |

---

## centro_custo

### Descrição

Cadastro dos Centros de Custos.

### Exemplos

Administrativo

Financeiro

Comercial

Operacional

Marketing

Turismo

Bike Tour

Tecnologia

Diretoria

---

## banco

### Descrição

Cadastro dos bancos.

### Exemplos

Banco do Brasil

Caixa

Itaú

Bradesco

Santander

Sicoob

Sicredi

Inter

Nubank

---

## agencia

### Descrição

Cadastro das agências bancárias.

Relacionamento:

Banco

↓

Agência

---

## conta_bancaria

### Descrição

Cadastro das contas bancárias.

### Informações

Banco

Agência

Conta

Tipo

Saldo Inicial

Saldo Atual

Empresa

Centro de Custo

---

## conta_financeira

### Descrição

Representa todas as contas financeiras utilizadas pelo ERP.

Pode representar:

- Conta Corrente
- Caixa
- Aplicação
- Carteira Digital

---

## lancamento_financeiro

### Descrição

Tabela central do módulo financeiro.

Todo evento financeiro gera um lançamento.

### Responsabilidade

Registrar:

Entradas

Saídas

Transferências

Estornos

Rateios

Ajustes

### Relacionamentos

Empresa

Plano de Conta

Centro de Custo

Conta Bancária

Cliente

Fornecedor

Projeto

Documento Fiscal

---

## contas_receber

### Descrição

Controle de recebimentos.

### Situações

Aberto

Recebido

Cancelado

Vencido

Renegociado

Parcial

---

## contas_pagar

### Descrição

Controle de pagamentos.

### Situações

Aberto

Pago

Cancelado

Vencido

Renegociado

Parcial

---

## fluxo_caixa

### Descrição

Controle diário do fluxo financeiro.

### Indicadores

Entradas

Saídas

Saldo Inicial

Saldo Final

Saldo Projetado

---

## conciliacao_bancaria

### Descrição

Controle da conciliação financeira.

### Objetivo

Garantir que:

Banco

=

ERP

---

## dre

### Descrição

Armazena os demonstrativos de resultado.

### Indicadores

Receita

Custos

Lucro Bruto

Despesas

Resultado Operacional

Lucro Líquido

---

## balancete

### Descrição

Balancete mensal do ERP.

Permite conferência contábil.

---

## aporte_capital

### Descrição

Registra aportes realizados pelos sócios.

### Informações

Valor

Empresa

Data

Forma

Observação

---

## distribuicao_lucros

### Descrição

Controla retiradas de lucros.

### Relacionamentos

Empresa

Sócio

Exercício

---

## transferencia_financeira

### Descrição

Transferências entre contas financeiras.

### Exemplos

Conta Corrente

↓

Caixa

↓

Aplicação

↓

Carteira

---

## historico_financeiro

### Descrição

Tabela de históricos padronizados.

Exemplos

Pagamento Fornecedor

Recebimento Cliente

Transferência

Aporte

Distribuição

Impostos

Salários

Tarifas

---

## fechamento_financeiro

### Descrição

Controla os fechamentos mensais.

### Objetivos

Bloquear alterações.

Gerar DRE.

Gerar Balancete.

Gerar Fluxo.

Gerar Indicadores.

---

## indicador_financeiro

### Descrição

Armazena KPIs financeiros calculados.

### Exemplos

Liquidez

Rentabilidade

Margem

Ticket Médio

Resultado

EBITDA

ROI

ROE

---

## dashboard_financeiro

### Descrição

Materialização dos indicadores utilizados pelos dashboards.

Utilizado pelo Power BI.

---

## 6.3 Módulo Comercial

O módulo **Comercial** concentra as operações relacionadas à gestão do relacionamento
com clientes e fornecedores, processos de vendas, CRM, propostas comerciais,
contratos e acompanhamento das oportunidades de negócio.
Relaciona-se ao ciclo de relacionamento comercial.

É responsável pelo ciclo completo de vendas do WMA Travel ERP, desde a prospecção até o faturamento.

---

## Visão Geral

## Objetivos

- Gerenciar clientes
- Gerenciar fornecedores
- Controlar vendas
- Gerenciar contratos
- Controlar propostas
- CRM
- Funil de vendas
- Indicadores comerciais

---

## cliente

### Descrição

Armazena todas as pessoas físicas e jurídicas que possuem relacionamento comercial com a empresa.

### Responsabilidade

Representa o cadastro principal de clientes.

### Chave Primária

| Coluna     |
| ---------- |
| id_cliente |

### Relacionamentos

| Tabela   | Cardinalidade |
| -------- | ------------- |
| empresa  | N:1           |
| endereco | 1:N           |
| contato  | 1:N           |
| venda    | 1:N           |
| contrato | 1:N           |
| proposta | 1:N           |
| reserva  | 1:N           |

### Colunas

| Coluna          | Tipo         | Nulo | Descrição          |
| --------------- | ------------ | ---- | ------------------ |
| id_cliente      | bigint       | Não  | Identificador      |
| id_empresa      | bigint       | Não  | Empresa            |
| tipo_pessoa     | varchar(2)   | Não  | PF/PJ              |
| nome            | varchar(255) | Não  | Nome/Razão Social  |
| cpf_cnpj        | varchar(20)  | Não  | Documento          |
| data_nascimento | date         | Sim  | Data nascimento    |
| email           | varchar(255) | Sim  | Email              |
| telefone        | varchar(30)  | Sim  | Telefone           |
| ativo           | boolean      | Não  | Situação           |
| created_at      | timestamp    | Não  | Auditoria          |
| updated_at      | timestamp    | Não  | Auditoria          |
| deleted_at      | timestamp    | Sim  | Auditoria          |
| created_by      | integer      | Sim  | Auditoria          |
| updated_by      | integer      | Sim  | Auditoria          |
| deleted_by      | integer      | Sim  | Auditoria          |
| versao          | integer      | Não  | Controle de versão |

### Índices

- pk_cliente
- uk_cliente_documento
- idx_cliente_empresa
- idx_cliente_nome

### Observações

Não permite exclusão física.

---

## fornecedor

### Descrição

Cadastro de fornecedores.

### Finalidade

Controlar empresas e pessoas fornecedoras.

### Exemplos

- Hotéis
- Companhias aéreas
- Restaurantes
- Guias
- Transportadoras
- Seguradoras

---

## contato

### Descrição

Cadastro de contatos vinculados a clientes ou fornecedores.

### Exemplos

- Financeiro
- Comercial
- Administrativo
- Gerente
- Diretor

---

## endereco

### Descrição

Cadastro de endereços.

### Utilização

Pode ser utilizado por:

- Cliente
- Fornecedor
- Empresa

### Tipos

- Comercial
- Cobrança
- Correspondência
- Residencial

---

## lead

### Descrição

Cadastro de potenciais clientes.

### Responsabilidade

Primeira etapa do CRM.

### Situações

- Novo
- Contatado
- Qualificado
- Perdido
- Convertido

---

## origem_lead

### Descrição

Origem dos Leads.

### Exemplos

- Website
- Google
- Facebook
- Instagram
- Indicação
- Evento
- WhatsApp
- Feira

---

## crm

### Descrição

Cadastro das oportunidades comerciais.

### Objetivo

Gerenciar todo relacionamento comercial.

---

## oportunidade

### Descrição

Representa uma oportunidade de venda.

### Situações

- Aberta
- Em negociação
- Ganha
- Perdida

---

## funil_venda

### Descrição

Controla o estágio comercial.

### Etapas

- Lead
- Contato
- Qualificação
- Proposta
- Negociação
- Fechamento

---

## proposta

### Descrição

Controle das propostas comerciais.

### Informações

- Cliente
- Data
- Validade
- Valor
- Status
- Responsável

### Situações

- Aberta
- Aprovada
- Rejeitada
- Cancelada

---

## contrato

### Descrição

Cadastro dos contratos.

### Pode representar

- Pacotes
- Prestação de serviços
- Eventos
- Turismo
- Bike Tour

---

## venda

### Descrição

Representa uma venda concluída.

### Relacionamentos

Cliente

↓

Proposta

↓

Contrato

↓

Financeiro

---

## item_venda

### Descrição

Itens pertencentes à venda.

### Exemplos

- Pacote
- Hotel
- Passeio
- Seguro
- Transporte

---

## campanha

### Descrição

Campanhas de marketing.

### Exemplos

- Black Friday
- Férias
- Natal
- Carnaval

---

## historico_cliente

### Descrição

Histórico completo das interações.

### Eventos

- Ligações
- Emails
- Reuniões
- Vendas
- Reclamações
- Reservas

---

## avaliacao_cliente

### Descrição

Avaliação dos serviços prestados.

### Indicadores

- Nota
- Comentário
- Satisfação
- NPS

---

## documento_cliente

### Descrição

Armazena documentos digitalizados.

### Exemplos

- CPF
- RG
- Passaporte
- CNH
- Contratos

---

## comissao_vendedor

### Descrição

Controle de comissões.

### Informações

- Vendedor
- Venda
- Percentual
- Valor

---

## vendedor

### Descrição

Cadastro da equipe comercial.

### Indicadores

- Meta
- Comissão
- Vendas
- Conversão

---

## meta_comercial

### Descrição

Metas da equipe comercial.

### Controle

- Mensal
- Trimestral
- Anual

---

## dashboard_comercial

### Descrição

Tabela utilizada para materialização dos indicadores do módulo Comercial.

### Indicadores

- Receita
- Conversão
- Ticket Médio
- Clientes Novos
- Propostas
- Contratos
- Vendas

---

## Fluxo Comercial

```text
Lead

↓

CRM

↓

Oportunidade

↓

Proposta

↓

Negociação

↓

Contrato

↓

Venda

↓

Financeiro

↓

Pós-venda
```

---

## Indicadores Comerciais

- Total de Clientes
- Clientes Ativos
- Leads
- Conversão
- Receita
- Ticket Médio
- Propostas
- Contratos
- Cancelamentos
- NPS

---

## 6.4 Módulo Fiscal

O módulo **Fiscal** é responsável pelo gerenciamento das obrigações tributárias,
emissão de documentos fiscais, apuração de impostos e integração com os órgãos
governamentais, assegurando a conformidade legal e o cumprimento da legislação
tributária vigente.

Seu objetivo é garantir a conformidade com a legislação tributária brasileira,
oferecendo suporte aos processos fiscais, financeiros e contábeis da empresa,
com foco na integridade das informações, na rastreabilidade das operações e no
cumprimento das obrigações legais.

---

### Visão Geral

### Objetivos

- Emissão de documentos fiscais
- Controle tributário
- Apuração de impostos
- Obrigações acessórias
- Integração com prefeituras
- Integração com SEFAZ
- Integração com Receita Federal
- Auditoria fiscal

---

## documento_fiscal

### Descrição

Tabela principal do módulo fiscal.

Armazena todos os documentos fiscais emitidos ou recebidos pelo ERP.

### Chave Primária

| Coluna              |
| ------------------- |
| id_documento_fiscal |

### Relacionamentos

| Tabela      | Cardinalidade |
| ----------- | ------------- |
| empresa     | N:1           |
| cliente     | N:1           |
| fornecedor  | N:1           |
| nota_fiscal | 1:N           |
| imposto     | 1:N           |

### Colunas

| Coluna              | Tipo        | Nulo | Descrição          |
| ------------------- | ----------- | ---- | ------------------ |
| id_documento_fiscal | bigint      | Não  | Identificador      |
| id_empresa          | bigint      | Não  | Empresa            |
| tipo_documento      | varchar(30) | Não  | Tipo fiscal        |
| numero              | varchar(30) | Não  | Número             |
| serie               | varchar(10) | Sim  | Série              |
| data_emissao        | timestamp   | Não  | Emissão            |
| situacao            | varchar(30) | Não  | Situação           |
| created_at          | timestamp   | Não  | Auditoria          |
| updated_at          | timestamp   | Não  | Auditoria          |
| deleted_at          | timestamp   | Sim  | Exclusão lógica    |
| created_by          | integer     | Sim  | Auditoria          |
| updated_by          | integer     | Sim  | Auditoria          |
| deleted_by          | integer     | Sim  | Auditoria          |
| versao              | integer     | Não  | Controle de versão |

### Índices

- pk_documento_fiscal
- idx_documento_empresa
- idx_documento_data
- idx_documento_tipo

---

## nota_fiscal

### Descrição

Cadastro das Notas Fiscais.

### Tipos

- NF-e
- NFS-e
- NFC-e
- CT-e
- MDF-e

### Situações

- Em digitação
- Emitida
- Autorizada
- Cancelada
- Denegada
- Rejeitada

---

## item_nota_fiscal

### Descrição

Itens pertencentes à nota fiscal.

### Informações

- Produto
- Serviço
- Quantidade
- Valor
- CFOP
- CST

---

## imposto

### Descrição

Cadastro dos tributos utilizados pelo ERP.

### Exemplos

- ISS
- ICMS
- IPI
- PIS
- COFINS
- IRPJ
- CSLL
- INSS
- IOF

---

## aliquota_imposto

### Descrição

Controla as alíquotas vigentes.

### Informações

- Imposto
- Estado
- Município
- Vigência
- Percentual

---

## apuracao_imposto

### Descrição

Resultado das apurações fiscais.

### Indicadores

- Base de cálculo
- Alíquota
- Valor
- Competência

---

## guia_recolhimento

### Descrição

Controle das guias tributárias.

### Exemplos

- DAS
- DARF
- GPS
- DAE
- ISSQN

---

## obrigacao_acessoria

### Descrição

Cadastro das obrigações acessórias.

### Exemplos

- DEFIS
- DCTFWeb
- EFD-Reinf
- SPED Fiscal
- SPED Contribuições
- DIRF
- RAIS
- eSocial

---

## declaracao_fiscal

### Descrição

Controle das declarações enviadas aos órgãos fiscais.

### Situações

- Em elaboração
- Validada
- Transmitida
- Retificada

---

## retenção_imposto

### Descrição

Controla tributos retidos.

### Exemplos

- INSS
- IRRF
- ISS
- PIS
- COFINS
- CSLL

---

## municipio

### Descrição

Cadastro de municípios utilizado para emissão fiscal.

### Relacionamentos

- Estado
- Código IBGE

---

## estado

### Descrição

Cadastro das Unidades Federativas.

### Campos

- UF
- Nome
- Código IBGE

---

## natureza_operacao

### Descrição

Naturezas utilizadas nas notas fiscais.

### Exemplos

- Venda
- Prestação de Serviço
- Devolução
- Bonificação
- Transferência

---

## cfop

### Descrição

Cadastro dos CFOP utilizados pelo ERP.

### Objetivo

Classificar corretamente as operações fiscais.

---

## cst

### Descrição

Cadastro dos CST.

### Exemplos

- ICMS
- PIS
- COFINS
- IPI

---

## ncm

### Descrição

Cadastro da Nomenclatura Comum do Mercosul.

Utilizado para classificação fiscal de produtos.

---

## certificado_digital

### Descrição

Controle dos certificados digitais utilizados.

### Informações

- Tipo
- Série
- Validade
- Responsável

---

## integracao_sefaz

### Descrição

Controle da comunicação com a SEFAZ.

### Eventos

- Autorização
- Cancelamento
- Consulta
- Carta de Correção

---

## integracao_prefeitura

### Descrição

Integração para emissão de NFS-e.

### Informações

- Município
- Web Service
- Ambiente
- Token

---

## dashboard_fiscal

### Descrição

Materialização dos indicadores fiscais.

### Indicadores

- Impostos por período
- Guias em aberto
- Obrigações pendentes
- Notas emitidas
- Notas canceladas
- Impostos recolhidos

---

## Fluxo Fiscal

```text
Venda

↓

Documento Fiscal

↓

Nota Fiscal

↓

Tributos

↓

Apuração

↓

Guia

↓

Pagamento

↓

Obrigações Acessórias
```

---

## Indicadores Fiscais

- Total de Notas Emitidas
- Total de Notas Canceladas
- ISS Recolhido
- ICMS Recolhido
- DAS Pago
- DAFF Pago
- Obrigações Pendentes
- Obrigações Entregues
- Valor Total de Tributos
- Certificados Próximos do Vencimento

---

## 6.5 Módulo Turismo

O módulo **Turismo** concentra as operações relacionadas ao planejamento,
comercialização, execução e acompanhamento dos produtos e serviços turísticos
oferecidos pela WMA Travel, abrangendo todas as etapas do ciclo operacional,
desde a criação dos roteiros até a conclusão das viagens e a avaliação dos
serviços prestados.

Este módulo integra-se diretamente aos módulos Comercial, Financeiro, Fiscal e CRM.

---

### Visão Geral

### Objetivos

- Gerenciar pacotes turísticos
- Controlar reservas
- Administrar hotéis
- Gerenciar voos
- Organizar passeios
- Emitir vouchers
- Controlar passageiros
- Integrar fornecedores
- Automatizar operações

---

## pacote_turistico

### Descrição

Cadastro dos pacotes turísticos comercializados pela empresa.

### Finalidade

Representa o principal produto vendido pela agência.

### Chave Primária

| Coluna    |
| --------- |
| id_pacote |

### Relacionamentos

| Tabela           | Cardinalidade |
| ---------------- | ------------- |
| destino          | N:1           |
| roteiro          | 1:N           |
| reserva          | 1:N           |
| fornecedor       | N:N           |
| categoria_pacote | N:1           |

### Colunas

| Coluna     | Tipo          | Nulo | Descrição            |
| ---------- | ------------- | ---- | -------------------- |
| id_pacote  | bigint        | Não  | Identificador        |
| codigo     | varchar(30)   | Não  | Código interno       |
| nome       | varchar(255)  | Não  | Nome do pacote       |
| descricao  | text          | Sim  | Descrição            |
| dias       | integer       | Não  | Quantidade de dias   |
| noites     | integer       | Não  | Quantidade de noites |
| valor_base | numeric(15,2) | Não  | Valor inicial        |
| ativo      | boolean       | Não  | Situação             |
| created_at | timestamp     | Não  | Auditoria            |
| updated_at | timestamp     | Não  | Auditoria            |
| deleted_at | timestamp     | Sim  | Exclusão lógica      |
| created_by | integer       | Sim  | Auditoria            |
| updated_by | integer       | Sim  | Auditoria            |
| deleted_by | integer       | Sim  | Auditoria            |
| versao     | integer       | Não  | Controle de versão   |

### Índices

- pk_pacote
- idx_pacote_nome
- idx_pacote_codigo

---

## categoria_pacote

### Descrição

Classificação dos pacotes turísticos.

### Exemplos

- Nacional
- Internacional
- Cruzeiro
- Ecoturismo
- Aventura
- Religioso
- Cultural
- Corporativo
- Pedagógico

---

## destino

### Descrição

Cadastro dos destinos turísticos.

### Exemplos

- Caldas Novas
- Porto Seguro
- Gramado
- Buenos Aires
- Punta Cana
- Lisboa

### Relacionamentos

Estado

↓

Cidade

↓

Destino

---

## roteiro

### Descrição

Define toda programação do pacote.

### Informações

- Dia
- Horário
- Atividade
- Local
- Responsável

---

## reserva

### Descrição

Representa uma reserva efetuada pelo cliente.

### Relacionamentos

Cliente

↓

Pacote

↓

Pagamento

↓

Voucher

↓

Viagem

### Situações

- Pré-reserva
- Confirmada
- Cancelada
- Finalizada

---

## passageiro

### Descrição

Cadastro dos passageiros.

### Informações

- Nome
- CPF
- Passaporte
- Nacionalidade
- Data de nascimento

---

## reserva_passageiro

### Descrição

Relaciona passageiros às reservas.

### Tipo

Tabela associativa (N:N).

---

## hotel

### Descrição

Cadastro dos hotéis parceiros.

### Informações

- Categoria
- Cidade
- Contato
- Avaliação
- Check-in
- Check-out

---

## acomodacao

### Descrição

Tipos de acomodações disponíveis.

### Exemplos

- Single
- Duplo
- Triplo
- Luxo
- Standard
- Master

---

## voo

### Descrição

Cadastro dos voos.

### Informações

- Companhia
- Origem
- Destino
- Horário
- Número

---

## companhia_aerea

### Descrição

Cadastro das companhias aéreas.

### Exemplos

- Azul
- Gol
- LATAM
- TAP
- Copa Airlines

---

## transporte

### Descrição

Cadastro dos meios de transporte.

### Exemplos

- Avião
- Ônibus
- Van
- Micro-ônibus
- Barco

---

## passeio

### Descrição

Cadastro dos passeios opcionais.

### Exemplos

- City Tour
- Passeio de Barco
- Trilha
- Parque Aquático
- Museu

---

## guia_turismo

### Descrição

Cadastro dos guias turísticos.

### Informações

- Credenciamento
- Idiomas
- Especialidades

---

## fornecedor_turistico

### Descrição

Cadastro específico de fornecedores do turismo.

### Exemplos

- Hotéis
- Restaurantes
- Transportadoras
- Agências receptivas
- Guias

---

## voucher

### Descrição

Documento emitido ao cliente para utilização dos serviços contratados.

### Informações

- Reserva
- Cliente
- Serviço
- Data
- QR Code

---

## seguro_viagem

### Descrição

Controle dos seguros contratados.

### Informações

- Seguradora
- Apólice
- Cobertura
- Validade

---

## embarque

### Descrição

Controle de embarques.

### Informações

- Local
- Horário
- Responsável
- Status

---

## excursao

### Descrição

Cadastro das excursões organizadas.

### Informações

- Destino
- Data
- Capacidade
- Responsável

---

## calendario_viagem

### Descrição

Agenda oficial das viagens.

### Objetivo

Planejamento operacional.

---

## ocorrencia_viagem

### Descrição

Registro de ocorrências durante a viagem.

### Exemplos

- Atrasos
- Cancelamentos
- Alterações
- Emergências

---

## avaliacao_viagem

### Descrição

Avaliação realizada pelo cliente após a viagem.

### Indicadores

- Atendimento
- Hotel
- Transporte
- Passeios
- Organização

---

## dashboard_turismo

### Descrição

Materialização dos indicadores turísticos.

### Indicadores

- Reservas
- Pacotes vendidos
- Destinos mais vendidos
- Ticket médio
- Cancelamentos
- Ocupação
- Receita
- Satisfação
- Avaliações
- Guias ativos

---

## Fluxo Operacional

```text
Cliente

↓

Pacote

↓

Reserva

↓

Pagamento

↓

Voucher

↓

Embarque

↓

Viagem

↓

Avaliação
```

---

## Indicadores do Turismo

- Pacotes Vendidos
- Reservas Confirmadas
- Reservas Canceladas
- Receita por Destino
- Receita por Pacote
- Ticket Médio
- Taxa de Ocupação
- Índice de Cancelamento
- Nível de Satisfação
- Destinos Mais Vendidos
- Hotéis Mais Utilizados
- Guias Mais Bem Avaliados
- Receita por Fornecedor

---

## 6.6 Módulo Bike Tour

O módulo **Bike Tour** é responsável pelo gerenciamento completo das operações de
cicloturismo da WMA Travel, incluindo o planejamento e a execução de eventos,
roteiros, inscrições, participantes, apoio logístico, bicicletas, pontos de
controle e monitoramento operacional, garantindo a organização, a segurança e
a rastreabilidade de todas as atividades.

Este módulo integra-se diretamente aos módulos Comercial, Financeiro, Turismo, CRM e Auditoria.

---

### Visão Geral

### Objetivos

- Gerenciar eventos ciclísticos
- Controlar inscrições
- Gerenciar participantes
- Planejar roteiros
- Controlar apoio logístico
- Emitir kits e credenciais
- Monitorar percursos
- Registrar ocorrências
- Avaliar eventos

---

## evento_bike

### Descrição

Cadastro dos eventos de cicloturismo organizados pela empresa.

### Finalidade

Representa o evento principal.

### Chave Primária

| Coluna         |
| -------------- |
| id_evento_bike |

### Relacionamentos

| Tabela         | Cardinalidade |
| -------------- | ------------- |
| roteiro_bike   | 1:N           |
| inscricao_bike | 1:N           |
| apoio_evento   | 1:N           |
| ponto_controle | 1:N           |

### Colunas

| Coluna          | Tipo          | Nulo | Descrição          |
| --------------- | ------------- | ---- | ------------------ |
| id_evento_bike  | bigint        | Não  | Identificador      |
| codigo          | varchar(30)   | Não  | Código interno     |
| nome            | varchar(255)  | Não  | Nome do evento     |
| descricao       | text          | Sim  | Descrição          |
| data_evento     | date          | Não  | Data               |
| cidade          | varchar(150)  | Não  | Cidade             |
| uf              | char(2)       | Não  | Estado             |
| vagas           | integer       | Não  | Número de vagas    |
| valor_inscricao | numeric(15,2) | Não  | Valor              |
| status          | varchar(30)   | Não  | Situação           |
| ativo           | boolean       | Não  | Situação           |
| created_at      | timestamp     | Não  | Auditoria          |
| updated_at      | timestamp     | Não  | Auditoria          |
| deleted_at      | timestamp     | Sim  | Exclusão lógica    |
| created_by      | integer       | Sim  | Auditoria          |
| updated_by      | integer       | Sim  | Auditoria          |
| deleted_by      | integer       | Sim  | Auditoria          |
| versao          | integer       | Não  | Controle de versão |

### Índices

- pk_evento_bike
- idx_evento_data
- idx_evento_cidade

---

## categoria_evento

### Descrição

Classificação dos eventos.

### Exemplos

- Cicloturismo
- Mountain Bike
- Speed
- Gravel
- Passeio Urbano
- Pedal Solidário
- Brevet
- Desafio

---

## roteiro_bike

### Descrição

Cadastro dos roteiros dos eventos.

### Informações

- Distância
- Altimetria
- Grau de dificuldade
- Tempo estimado
- Pontos de apoio

---

## percurso_bike

### Descrição

Representa os percursos oficiais.

### Informações

- Quilometragem
- Ganho de elevação
- Tipo de terreno
- Tempo médio

---

## inscricao_bike

### Descrição

Controle das inscrições.

### Situações

- Pré-inscrito
- Confirmado
- Pago
- Cancelado
- Presente
- Ausente

---

## participante_bike

### Descrição

Cadastro dos participantes.

### Informações

- Nome
- CPF
- Data nascimento
- Contato
- Categoria

---

## bicicleta

### Descrição

Cadastro das bicicletas utilizadas.

### Exemplos

- MTB
- Speed
- Gravel
- Elétrica
- Urbana

---

## categoria_bicicleta

### Descrição

Classificação das bicicletas.

### Exemplos

- Alumínio
- Carbono
- Full Suspension
- Hardtail

---

## kit_evento

### Descrição

Controle dos kits entregues aos participantes.

### Itens

- Camisa
- Medalha
- Número
- Chip
- Brindes

---

## entrega_kit

### Descrição

Registro da entrega dos kits.

### Informações

- Data
- Responsável
- Participante

---

## apoio_evento

### Descrição

Cadastro das equipes de apoio.

### Exemplos

- Mecânica
- Ambulância
- Água
- Alimentação
- Transporte

---

## ponto_controle

### Descrição

Cadastro dos pontos de controle do percurso.

### Informações

- Quilômetro
- Coordenadas
- Tipo

---

## checkin_participante

### Descrição

Registro da passagem do participante pelos pontos de controle.

### Objetivo

Controle de segurança e tempo.

---

## ocorrencia_evento

### Descrição

Registro das ocorrências durante o evento.

### Exemplos

- Acidente
- Atendimento médico
- Problema mecânico
- Abandono
- Alteração do percurso

---

## patrocinador

### Descrição

Cadastro dos patrocinadores.

### Informações

- Empresa
- Cota
- Valor
- Contrapartidas

---

## parceiro_evento

### Descrição

Cadastro dos parceiros institucionais.

### Exemplos

- Prefeitura
- Polícia Militar
- Bombeiros
- Sesc
- Clubes

---

## cronometragem

### Descrição

Controle de tempos dos participantes.

### Informações

- Largada
- Chegada
- Tempo líquido
- Tempo bruto

---

## classificacao_evento

### Descrição

Resultado oficial do evento.

### Critérios

- Categoria
- Sexo
- Faixa etária
- Geral

---

## certificado_participacao

### Descrição

Controle dos certificados emitidos.

### Informações

- Participante
- Evento
- Data
- Código de validação

---

## avaliacao_evento

### Descrição

Avaliação do evento pelos participantes.

### Indicadores

- Organização
- Percurso
- Apoio
- Segurança
- Estrutura
- Satisfação geral

---

## dashboard_bike

### Descrição

Tabela de materialização dos indicadores do módulo Bike Tour.

### Indicadores

- Eventos realizados
- Participantes inscritos
- Participantes presentes
- Receita por evento
- Receita por inscrição
- Ticket médio
- Distância total percorrida
- Ocorrências registradas
- Patrocinadores ativos
- Índice de satisfação

---

### Fluxo Operacional

```text
Evento

↓

Inscrição

↓

Pagamento

↓

Entrega do Kit

↓

Check-in

↓

Largada

↓

Pontos de Controle

↓

Chegada

↓

Classificação

↓

Certificado

↓

Avaliação
```

---

## Indicadores do Bike Tour

- Eventos realizados
- Eventos planejados
- Participantes inscritos
- Participantes confirmados
- Participantes presentes
- Taxa de comparecimento
- Receita por evento
- Receita por patrocinador
- Ticket médio
- Distância percorrida
- Tempo médio
- Ocorrências
- Acidentes
- Índice de satisfação
- NPS do evento

---

## 6.7 Módulo Recursos Humanos

O módulo Recursos Humanos (RH) é responsável pelo gerenciamento dos colaboradores,
departamentos, cargos, jornadas,folha de pagamento, benefícios, férias,
treinamentos e demais processos relacionados à gestão de pessoas.

Este módulo integra-se diretamente aos módulos Financeiro, Administrativo, Auditoria e Governança.

---

### Visão Geral

### Objetivos

- Gerenciar colaboradores
- Controlar departamentos
- Gerenciar cargos
- Controlar admissões
- Controlar desligamentos
- Gerenciar folha de pagamento
- Controlar férias
- Controlar benefícios
- Registrar treinamentos
- Controlar ponto eletrônico

---

## colaborador

### Descrição

Cadastro principal dos colaboradores da empresa.

### Finalidade

Representa todos os empregados, estagiários, aprendizes, temporários e prestadores internos cadastrados no ERP.

### Chave Primária

| Coluna         |
| -------------- |
| id_colaborador |

### Relacionamentos

| Tabela          | Cardinalidade |
| --------------- | ------------- |
| empresa         | N:1           |
| departamento    | N:1           |
| cargo           | N:1           |
| folha_pagamento | 1:N           |
| ferias          | 1:N           |
| ponto           | 1:N           |
| treinamento     | N:N           |

### Colunas

| Coluna          | Tipo          | Nulo | Descrição          |
| --------------- | ------------- | ---- | ------------------ |
| id_colaborador  | bigint        | Não  | Identificador      |
| id_empresa      | bigint        | Não  | Empresa            |
| id_departamento | bigint        | Não  | Departamento       |
| id_cargo        | bigint        | Não  | Cargo              |
| nome            | varchar(255)  | Não  | Nome completo      |
| cpf             | varchar(14)   | Não  | CPF                |
| data_admissao   | date          | Não  | Admissão           |
| data_demissao   | date          | Sim  | Demissão           |
| salario         | numeric(15,2) | Não  | Salário base       |
| status          | varchar(20)   | Não  | Situação           |
| created_at      | timestamp     | Não  | Auditoria          |
| updated_at      | timestamp     | Não  | Auditoria          |
| deleted_at      | timestamp     | Sim  | Exclusão lógica    |
| created_by      | integer       | Sim  | Auditoria          |
| updated_by      | integer       | Sim  | Auditoria          |
| deleted_by      | integer       | Sim  | Auditoria          |
| versao          | integer       | Não  | Controle de versão |

### Índices

- pk_colaborador
- uk_colaborador_cpf
- idx_colaborador_empresa
- idx_colaborador_departamento

---

## departamento

### Descrição

Cadastro dos departamentos da empresa.

### Exemplos

- Administrativo
- Financeiro
- Comercial
- Operações
- Turismo
- Bike Tour
- Tecnologia
- Diretoria

---

## cargo

### Descrição

Cadastro dos cargos existentes.

### Exemplos

- Diretor
- Gerente
- Supervisor
- Analista
- Assistente
- Consultor
- Guia de Turismo
- Recreador

---

## jornada_trabalho

### Descrição

Define a jornada contratual do colaborador.

### Exemplos

- 44 horas
- 40 horas
- 36 horas
- Escala 12x36
- Meio período

---

## ponto

### Descrição

Controle dos registros de ponto.

### Informações

- Entrada
- Saída
- Intervalo
- Horas extras
- Banco de horas

---

## banco_horas

### Descrição

Controle do saldo de horas dos colaboradores.

### Indicadores

- Horas positivas
- Horas negativas
- Compensações

---

## folha_pagamento

### Descrição

Controle mensal da folha de pagamento.

### Componentes

- Salário
- Horas extras
- Adicionais
- Descontos
- Encargos
- Líquido

---

## beneficio

### Descrição

Cadastro dos benefícios oferecidos.

### Exemplos

- Vale Transporte
- Vale Alimentação
- Plano de Saúde
- Seguro de Vida
- Auxílio Combustível

---

## colaborador_beneficio

### Descrição

Relaciona colaboradores aos benefícios concedidos.

### Tipo

Tabela associativa (N:N).

---

## ferias

### Descrição

Controle de férias.

### Informações

- Período aquisitivo
- Período concessivo
- Data início
- Data fim
- Abono pecuniário

---

## afastamento

### Descrição

Registro dos afastamentos dos colaboradores.

### Exemplos

- INSS
- Licença maternidade
- Licença paternidade
- Acidente de trabalho
- Licença médica

---

## treinamento

### Descrição

Cadastro dos treinamentos corporativos.

### Exemplos

- Atendimento ao Cliente
- Primeiros Socorros
- LGPD
- Segurança da Informação
- Turismo Receptivo

---

## colaborador_treinamento

### Descrição

Relaciona colaboradores aos treinamentos realizados.

---

## avaliacao_desempenho

### Descrição

Controle das avaliações periódicas dos colaboradores.

### Critérios

- Competências
- Metas
- Comportamento
- Produtividade

---

## dashboard_rh

### Descrição

Tabela de materialização dos indicadores do módulo RH.

### Indicadores

- Colaboradores ativos
- Admitidos
- Desligados
- Férias programadas
- Horas extras
- Absenteísmo
- Treinamentos realizados
- Avaliações concluídas
- Custo da folha
- Benefícios concedidos

---

### Fluxo Operacional

```text
Admissão

↓

Cadastro

↓

Jornada

↓

Ponto

↓

Folha

↓

Benefícios

↓

Férias

↓

Treinamentos

↓

Avaliação

↓

Desligamento
```

---

## Indicadores de Recursos Humanos

- Total de colaboradores
- Colaboradores ativos
- Admissões
- Desligamentos
- Turnover
- Absenteísmo
- Horas extras
- Banco de horas
- Custo da folha
- Benefícios
- Treinamentos realizados
- Avaliações concluídas
- Índice de produtividade

---
---

## 6.8 Framework de Auditoria

O Framework de Auditoria é responsável pela validação estrutural, documental,
funcional e operacional do banco de dados do WMA Travel ERP.

Seu objetivo é garantir que todas as estruturas do banco estejam
em conformidade com os padrões corporativos definidos pelo projeto.

Este framework permite a certificação automática do banco de dados por meio do Índice de Conformidade do Banco (ICB).

---

### Visão Geral

### Objetivos

- Auditoria estrutural
- Auditoria documental
- Auditoria de segurança
- Auditoria de índices
- Auditoria de Foreign Keys
- Auditoria de Views
- Auditoria de Procedures
- Auditoria de Functions
- Auditoria de Triggers
- Auditoria de Comentários
- Auditoria de Performance
- Plano Automático de Correção
- Certificação Técnica

---

## execucao_auditoria

### Descrição

Controla cada execução do processo de auditoria do banco de dados.

Cada execução recebe um identificador único que agrupa todos os resultados produzidos.

### Chave Primária

| Coluna      |
| ----------- |
| id_execucao |

### Colunas

| Coluna            | Tipo         | Descrição     |
| ----------------- | ------------ | ------------- |
| id_execucao       | bigint       | Identificador |
| data_inicio       | timestamp    | Início        |
| data_fim          | timestamp    | Término       |
| usuario_execucao  | varchar(100) | Usuário       |
| versao_banco      | varchar(50)  | PostgreSQL    |
| versao_framework  | varchar(20)  | Framework     |
| status            | varchar(30)  | Situação      |
| tempo_execucao_ms | bigint       | Tempo         |

### Índices

- pk_execucao_auditoria
- idx_execucao_data

---

## auditoria_categoria

### Descrição

Cadastro das categorias auditadas.

### Exemplos

- Estrutura
- Segurança
- Performance
- Documentação
- Índices
- Constraints
- Foreign Keys
- Views
- Procedures
- Functions
- Triggers

---

## auditoria_item

### Descrição

Define cada item verificável durante uma auditoria.

### Exemplos

- Todas as tabelas possuem PK
- Todas as FKs possuem índice
- Todas as tabelas possuem comentários
- Todas as colunas possuem documentação
- Todas possuem auditoria

---

## auditoria_resultado

### Descrição

Armazena o resultado individual de cada verificação.

### Situações

- OK
- ALERTA
- ERRO
- CRÍTICO

### Relacionamentos

Execução

↓

Categoria

↓

Item

↓

Resultado

---

## auditoria_score

### Descrição

Armazena a pontuação obtida por categoria.

### Indicadores

- Estrutura
- Segurança
- Documentação
- Performance
- Governança

---

## auditoria_certificacao

### Descrição

Resultado final da auditoria.

### Classificações

- Não Conforme
- Conforme com Restrições
- Conforme
- Certificado para Produção

---

## plano_correcao

### Descrição

Lista automaticamente todas as correções necessárias.

### Informações

- Problema
- Severidade
- Script sugerido
- Responsável
- Prazo

---

## plano_correcao_item

### Descrição

Itens pertencentes ao plano de correção.

Cada item corresponde a um problema identificado.

---

## revalidacao

### Descrição

Controla as revalidações realizadas após correções.

### Objetivo

Confirmar que os problemas foram solucionados.

---

## auditoria_objeto

### Descrição

Cadastro dos objetos auditáveis.

### Tipos

- Tabela
- View
- Procedure
- Function
- Trigger
- Índice
- Constraint
- Sequence

---

## auditoria_documentacao

### Descrição

Avalia a documentação técnica do banco.

### Critérios

- COMMENT ON TABLE
- COMMENT ON COLUMN
- COMMENT ON VIEW
- COMMENT ON FUNCTION

---

## auditoria_indices

### Descrição

Audita todos os índices do banco.

### Verificações

- Índices duplicados
- Índices ausentes
- Índices não utilizados

---

## auditoria_fk

### Descrição

Audita as Foreign Keys.

### Critérios

- Existência
- Índice correspondente
- Integridade referencial

---

## auditoria_performance

### Descrição

Monitora indicadores de desempenho.

### Métricas

- Tempo médio
- Leituras
- Escritas
- Seq Scan
- Index Scan

---

## auditoria_seguranca

### Descrição

Avalia a configuração de segurança.

### Critérios

- Owners
- Roles
- Grants
- Schemas
- Permissões

---

## auditoria_healthcheck

### Descrição

Executa verificações gerais do ambiente.

### Exemplos

- Tabelas órfãs
- Constraints inválidas
- Objetos sem uso
- Objetos inválidos

---

## dashboard_auditoria

### Descrição

Materialização dos indicadores utilizados pelo Dashboard Técnico.

### Indicadores

- Total de Auditorias
- Tempo Médio
- Score Geral
- ICB
- Problemas Críticos
- Problemas Resolvidos
- Objetos Auditados
- Objetos Certificados

---

## Fluxo da Auditoria

```text
Execução

↓

Categorias

↓

Itens

↓

Resultados

↓

Score

↓

Plano de Correção

↓

Revalidação

↓

Certificação

↓

Dashboard
```

---

## Índice de Conformidade do Banco (ICB)

O Framework calcula automaticamente o ICB utilizando critérios ponderados.

## Faixas

| ICB    | Classificação             |
| ------ | ------------------------- |
| 0–59   | Não Conforme              |
| 60–79  | Conforme com Restrições   |
| 80–94  | Conforme                  |
| 95–100 | Certificado para Produção |

---

## Indicadores Técnicos

- Total de Objetos Auditados
- Total de Tabelas
- Total de Views
- Total de Procedures
- Total de Functions
- Total de Triggers
- Total de Índices
- Total de Foreign Keys
- Total de Comentários
- Total de Problemas
- Total de Problemas Críticos
- Percentual de Documentação
- Percentual de Auditoria
- ICB Geral
- Tempo Médio de Auditoria

---

## 6.9 Framework de Governança

O Framework de Governança estabelece todas as políticas, normas,
controles e mecanismos necessários para garantir integridade, rastreabilidade,
conformidade e padronização do banco de dados do WMA Travel ERP.

Sua principal finalidade é assegurar que o ambiente permaneça consistente durante toda a evolução do sistema.

---

### Visão Geral

### Objetivos

- Padronização do banco
- Controle de versões
- Gestão de mudanças
- Governança de dados
- Catálogo de metadados
- LGPD
- Segurança
- Compliance
- Integridade referencial
- Gestão documental

---

## governanca_politica

### Descrição

Cadastro das políticas de governança aplicadas ao ERP.

### Exemplos

- Política de Backup
- Política de Auditoria
- Política de Segurança
- Política LGPD
- Política de Versionamento
- Política de Desenvolvimento

---

## governanca_categoria

### Descrição

Classificação das políticas.

### Exemplos

- Segurança
- Banco de Dados
- Desenvolvimento
- Infraestrutura
- Compliance
- Auditoria

---

## governanca_documento

### Descrição

Cadastro dos documentos oficiais da governança.

### Exemplos

- Manual DBA
- Manual Desenvolvedor
- Arquitetura
- Data Dictionary
- API
- Roadmap

---

## governanca_versao

### Descrição

Controle das versões do banco de dados.

### Informações

| Campo       | Descrição |
| ----------- | --------- |
| Versão      |
| Data        |
| Autor       |
| Ambiente    |
| Observações |

---

## governanca_release

### Descrição

Controle das releases publicadas.

### Exemplos

- 1.0.0
- 1.1.0
- 1.2.0

---

## governanca_migracao

### Descrição

Histórico de migrações executadas.

### Informações

- Script
- Data
- Responsável
- Tempo
- Status

---

## governanca_change

### Descrição

Registro de alterações estruturais.

### Eventos

- CREATE
- ALTER
- DROP
- RENAME
- COMMENT

---

## governanca_aprovacao

### Descrição

Controle das aprovações das mudanças.

### Fluxo

Solicitação

↓

Análise

↓

Aprovação

↓

Execução

↓

Homologação

↓

Produção

---

## governanca_risco

### Descrição

Cadastro dos riscos identificados.

### Classificações

- Baixo
- Médio
- Alto
- Crítico

---

## governanca_incidente

### Descrição

Registro de incidentes.

### Exemplos

- Falha de Backup
- Queda de Banco
- Corrupção
- Lentidão
- Segurança

---

## governanca_lgpd

### Descrição

Controle dos requisitos da Lei Geral de Proteção de Dados.

### Informações

- Base Legal
- Consentimento
- Finalidade
- Retenção
- Anonimização

---

## governanca_log

### Descrição

Registro consolidado de eventos administrativos.

### Exemplos

- Login
- Alteração
- Exclusão
- Backup
- Restore

---

## governanca_backup

### Descrição

Controle dos backups realizados.

### Informações

- Tipo
- Data
- Ambiente
- Local
- Responsável

---

## governanca_restore

### Descrição

Registro dos testes de restauração.

### Objetivo

Garantir recuperação do ambiente.

---

## governanca_ambiente

### Descrição

Cadastro dos ambientes.

### Exemplos

- Desenvolvimento
- Homologação
- Produção
- Backup

---

## governanca_servidor

### Descrição

Cadastro dos servidores.

### Informações

- Host
- Sistema Operacional
- PostgreSQL
- Memória
- CPU

---

## governanca_role

### Descrição

Cadastro das Roles do PostgreSQL.

### Exemplos

- dba
- administrador
- desenvolvedor
- leitura
- auditor

---

## governanca_permissao

### Descrição

Controle das permissões concedidas.

### Objetivos

- Menor privilégio
- Segregação de funções
- Auditoria

---

## governanca_compliance

### Descrição

Controle de conformidade.

### Critérios

- ISO 27001
- LGPD
- Boas práticas PostgreSQL
- Normas internas

---

## governanca_metadata

### Descrição

Catálogo corporativo de metadados.

### Conteúdo

- Tabelas
- Colunas
- Índices
- Views
- Procedures
- Functions

---

## dashboard_governanca

### Descrição

Materialização dos indicadores de governança.

### Indicadores

- Políticas Ativas
- Versões
- Releases
- Migrações
- Backups
- Restores
- Incidentes
- Compliance
- LGPD
- Score Geral

---

## Fluxo de Governança

```text
Política

↓

Versionamento

↓

Mudança

↓

Aprovação

↓

Migração

↓

Auditoria

↓

Certificação

↓

Produção
```

---

## Indicadores de Governança

- Políticas implantadas
- Versões publicadas
- Releases homologadas
- Migrações executadas
- Backups realizados
- Restores testados
- Incidentes
- Tempo médio de recuperação (RTO)
- Perda máxima aceitável (RPO)
- Conformidade LGPD
- Compliance
- Score de Governança

---

## Integração com Outros Frameworks

O Framework de Governança integra-se diretamente com:

- Framework de Auditoria
- Framework de Certificação
- Framework de Segurança
- Framework de Versionamento
- Framework DBA
- Dashboard Executivo

---

## Benefícios

- Padronização corporativa
- Controle de mudanças
- Rastreabilidade completa
- Segurança da informação
- Conformidade legal
- Facilidade de auditoria
- Evolução controlada
- Base para certificação técnica

---

## 6.10 Views

As Views do WMA Travel ERP possuem como objetivo disponibilizar informações consolidadas para consultas, dashboards, APIs e Business Intelligence.

As Views nunca armazenam dados permanentemente.

Sua função é consolidar informações provenientes das tabelas transacionais.

---

### Objetivos

- Simplificar consultas
- Padronizar indicadores
- Reduzir duplicidade de SQL
- Apoiar Power BI
- Apoiar APIs
- Melhorar performance analítica
- Centralizar regras de negócio

---

## Convenções

Todas as Views seguem o padrão:

```text
vw_<nome>
```

Exemplos:

```text
vw_clientes
vw_fluxo_caixa
vw_dre
vw_dashboard_financeiro
vw_indicadores_auditoria
```

---

## Classificação

As Views estão organizadas em:

- Operacionais
- Financeiras
- Comerciais
- Fiscais
- Turismo
- Bike Tour
- RH
- Auditoria
- Governança
- Dashboards

---

## vw_empresa

### Descrição

Retorna informações consolidadas da empresa.

### Origem

- empresa

### Utilização

- Dashboard
- Cadastro
- API

---

## vw_clientes

### Descrição

Lista consolidada de clientes ativos.

### Origem

- cliente
- endereco
- contato

### Campos principais

- id_cliente
- nome
- documento
- telefone
- email
- cidade
- uf
- status

---

## vw_fornecedores

### Descrição

Consulta consolidada dos fornecedores.

### Origem

- fornecedor
- endereco

---

## vw_colaboradores

### Descrição

Consulta completa dos colaboradores.

### Origem

- colaborador
- departamento
- cargo

---

## vw_contas_receber

### Descrição

Consulta financeira das contas a receber.

### Origem

- contas_receber
- cliente
- plano_conta

### Indicadores

- Total
- Em aberto
- Recebido
- Vencido

---

## vw_contas_pagar

### Descrição

Consulta consolidada das contas a pagar.

### Origem

- contas_pagar
- fornecedor

---

## vw_fluxo_caixa

### Descrição

Fluxo de caixa diário consolidado.

### Origem

- lancamento_financeiro

### Indicadores

- Entradas
- Saídas
- Saldo

---

## vw_dre

### Descrição

Demonstração do Resultado do Exercício.

### Origem

- plano_conta
- lancamento_financeiro

### Indicadores

- Receita
- Custos
- Despesas
- Resultado

---

## vw_balancete

### Descrição

Balancete consolidado.

### Origem

- plano_conta
- lancamentos

---

## vw_reservas

### Descrição

Lista consolidada das reservas.

### Origem

- reserva
- cliente
- pacote_turistico

---

## vw_pacotes

### Descrição

Consulta dos pacotes turísticos.

### Origem

- pacote_turistico
- destino

---

## vw_eventos_bike

### Descrição

Eventos do Bike Tour.

### Origem

- evento_bike

---

## vw_participantes_bike

### Descrição

Participantes dos eventos.

### Origem

- participante_bike
- inscricao_bike

---

## vw_dashboard_financeiro

### Descrição

View utilizada exclusivamente pelo Dashboard Financeiro.

### Indicadores

- Receita
- Despesa
- Lucro
- Caixa
- Saldo

---

## vw_dashboard_comercial

### Descrição

Indicadores comerciais.

### Indicadores

- Clientes
- Vendas
- Ticket Médio
- Conversão

---

## vw_dashboard_turismo

### Descrição

Indicadores do Turismo.

### Indicadores

- Reservas
- Pacotes
- Receita
- Cancelamentos

---

## vw_dashboard_bike

### Descrição

Indicadores do Bike Tour.

### Indicadores

- Eventos
- Participantes
- Receita
- Avaliações

---

## vw_dashboard_rh

### Descrição

Indicadores de Recursos Humanos.

### Indicadores

- Colaboradores
- Folha
- Horas Extras
- Turnover

---

## vw_dashboard_fiscal

### Descrição

Indicadores fiscais.

### Indicadores

- Notas Emitidas
- Impostos
- Guias
- Obrigações

---

## vw_dashboard_governanca

### Descrição

Indicadores do Framework de Governança.

### Indicadores

- Compliance
- LGPD
- Releases
- Migrações

---

## vw_dashboard_auditoria

### Descrição

Indicadores do Framework de Auditoria.

### Indicadores

- ICB
- Score
- Problemas
- Certificação

---

## vw_health_check

### Descrição

Resumo técnico do banco.

### Indicadores

- Tabelas
- Views
- Procedures
- Functions
- Triggers
- Índices
- Constraints

---

## vw_indicadores_auditoria

### Descrição

View responsável pelo cálculo consolidado do Índice de Conformidade do Banco (ICB).

### Origem

- auditoria_resultado
- auditoria_score
- auditoria_certificacao

### Indicadores

- Score Geral
- Percentual
- Categoria
- Criticidade

---

## Dependências

As Views dependem diretamente de:

- Tabelas
- Functions
- Procedures
- Índices
- Materialized Views

---

## Boas Práticas

As Views devem:

- Possuir COMMENT ON VIEW
- Possuir COMMENT ON COLUMN
- Não utilizar SELECT *
- Utilizar aliases padronizados
- Ser documentadas no Framework DBA
- Possuir versionamento

---

## Convenções de Nomenclatura

| Prefixo | Significado       |
| ------- | ----------------- |
| vw_     | View              |
| mvw_    | Materialized View |

---

## Indicadores Cobertos

As Views suportam indicadores dos módulos:

- Administrativo
- Financeiro
- Comercial
- Fiscal
- Turismo
- Bike Tour
- Recursos Humanos
- Auditoria
- Governança

---

## Estatísticas do Projeto

Previsão para a versão 1.0.0:

| Objeto             | Quantidade Estimada |
| ------------------ | ------------------: |
| Views Operacionais |                  18 |
| Views Financeiras  |                  12 |
| Views Comerciais   |                  10 |
| Views Fiscais      |                   8 |
| Views Turismo      |                  10 |
| Views Bike Tour    |                   8 |
| Views RH           |                   6 |
| Views Auditoria    |                  12 |
| Views Governança   |                  10 |
| **Total Estimado** |        **94 Views** |

---

## 6.11 Procedures

As Stored Procedures do WMA Travel ERP concentram processos automatizados responsáveis pela execução de rotinas administrativas,
financeiras, fiscais, operacionais e de auditoria.

O objetivo é centralizar regras críticas de negócio dentro do PostgreSQL, garantindo padronização, desempenho e segurança.

---

### Objetivos

As Procedures possuem como finalidade:

- Automatizar processos
- Garantir integridade
- Reduzir código duplicado
- Executar processos em lote
- Padronizar regras corporativas
- Facilitar manutenção
- Melhorar desempenho

---

### Convenções

Todas as Procedures seguem o padrão:

```text
sp_<nome>
```

Exemplos

```text
sp_fechamento_financeiro
sp_calcular_icb
sp_executar_auditoria
sp_revalidar_banco
```

---

## Organização

As Procedures estão organizadas por módulos.

```text
Administrativo

Financeiro

Comercial

Fiscal

Turismo

Bike Tour

RH

Auditoria

Governança

Sistema
```

---

## Estrutura da Documentação

Cada Procedure possui as seguintes informações:

- Nome
- Finalidade
- Responsabilidade
- Parâmetros
- Retorno
- Dependências
- Observações

---

## Procedures Administrativas

---

## sp_cadastrar_empresa

### Descrição

Realiza o cadastro completo da empresa.

### Objetivo

Garantir a criação consistente dos registros iniciais.

### Parâmetros

| Nome   | Tipo    |
| ------ | ------- |
| p_nome | varchar |
| p_cnpj | varchar |

### Retorno

Identificador da empresa.

---

## sp_atualizar_empresa

### Descrição

Atualiza os dados cadastrais da empresa.

---

## sp_inativar_empresa

### Descrição

Realiza exclusão lógica da empresa.

---

## Procedures Financeiras

---

## sp_gerar_fluxo_caixa

### Descrição

Atualiza o Fluxo de Caixa.

### Responsabilidade

Recalcular entradas, saídas e saldo.

---

## sp_recalcular_saldos

### Descrição

Recalcula todos os saldos financeiros.

---

## sp_fechamento_financeiro

### Descrição

Executa o fechamento financeiro mensal.

### Processos

- Atualização dos saldos
- Conferência
- Encerramento

---

## sp_abrir_competencia

### Descrição

Abre uma nova competência financeira.

---

## sp_fechar_competencia

### Descrição

Fecha oficialmente a competência.

---

## sp_reabrir_competencia

### Descrição

Permite reabertura mediante autorização.

---

## sp_calcular_dre

### Descrição

Calcula automaticamente a Demonstração do Resultado.

---

## sp_calcular_balancete

### Descrição

Atualiza o Balancete.

---

## Procedures Comerciais

---

## sp_converter_lead

### Descrição

Converte Lead em Cliente.

---

## sp_gerar_proposta

### Descrição

Gera proposta comercial.

---

## sp_fechar_venda

### Descrição

Finaliza uma venda.

---

## sp_cancelar_venda

### Descrição

Cancela venda respeitando regras de negócio.

---

## Procedures Fiscais

---

## sp_emitir_nf

### Descrição

Executa emissão da Nota Fiscal.

---

## sp_cancelar_nf

### Descrição

Solicita cancelamento.

---

## sp_apurar_impostos

### Descrição

Realiza apuração tributária.

---

## sp_gerar_das

### Descrição

Calcula DAS.

---

## sp_gerar_darf

### Descrição

Calcula DARF.

---

## Procedures Turismo

---

## sp_confirmar_reserva

### Descrição

Confirma reserva turística.

---

## sp_cancelar_reserva

### Descrição

Cancela reserva.

---

## sp_emitir_voucher

### Descrição

Gera Voucher.

---

## sp_gerar_roteiro

### Descrição

Monta roteiro da viagem.

---

## Procedures Bike Tour

---

## sp_confirmar_inscricao

### Descrição

Confirma inscrição.

---

## sp_entregar_kit

### Descrição

Registra entrega do kit.

---

## sp_registrar_checkin

### Descrição

Efetua check-in do participante.

---

## sp_classificar_evento

### Descrição

Calcula classificação.

---

## sp_emitir_certificado

### Descrição

Emite certificado digital.

---

## Procedures RH

---

## sp_calcular_folha

### Descrição

Calcula folha de pagamento.

---

## sp_calcular_ferias

### Descrição

Calcula férias.

---

## sp_processar_ponto

### Descrição

Processa registros de ponto.

---

## Procedures Auditoria

---

## sp_executar_auditoria

### Descrição

Executa auditoria completa.

---

## sp_auditar_colunas

### Descrição

Verifica colunas padrão.

---

## sp_auditar_indices

### Descrição

Verifica índices.

---

## sp_auditar_documentacao

### Descrição

Audita documentação.

---

## sp_auditar_seguranca

### Descrição

Audita permissões.

---

## sp_calcular_score

### Descrição

Calcula Score Geral.

---

## sp_calcular_icb

### Descrição

Calcula o Índice de Conformidade do Banco.

---

## sp_gerar_plano_correcao

### Descrição

Gera plano automático de correção.

---

## sp_revalidar_banco

### Descrição

Executa revalidação.

---

## sp_certificar_banco

### Descrição

Realiza certificação técnica.

---

## Procedures Governança

---

## sp_registrar_release

### Descrição

Registra nova release.

---

## sp_registrar_migracao

### Descrição

Registra migração.

---

## sp_registrar_backup

### Descrição

Registra backup.

---

## sp_registrar_restore

### Descrição

Registra restore.

---

## sp_atualizar_metadata

### Descrição

Atualiza catálogo de metadados.

---

## Procedures do Sistema

---

## sp_health_check

### Descrição

Executa diagnóstico completo.

---

## sp_limpeza_logs

### Descrição

Executa limpeza programada.

---

## sp_reindex_database

### Descrição

Reconstrói índices.

---

## sp_vacuum_database

### Descrição

Executa VACUUM.

---

## sp_analyze_database

### Descrição

Atualiza estatísticas.

---

### Convenções

Todas as Procedures deverão:

- possuir COMMENT ON
- possuir controle de versão
- registrar execução em log
- possuir tratamento de exceções
- utilizar transações
- evitar SQL dinâmico quando possível

---

### Dependências

As Procedures podem utilizar:

- Functions
- Views
- Triggers
- Sequences
- Tabelas
- Materialized Views

---

### Estatísticas Previstas

| Categoria          |         Quantidade |
| ------------------ | -----------------: |
| Administrativas    |                 10 |
| Financeiras        |                 18 |
| Comerciais         |                 10 |
| Fiscais            |                 10 |
| Turismo            |                 12 |
| Bike Tour          |                  8 |
| RH                 |                  8 |
| Auditoria          |                 15 |
| Governança         |                 10 |
| Sistema            |                 12 |
| **Total Estimado** | **113 Procedures** |

---

## 6.12 Functions

As Functions do WMA Travel ERP implementam regras reutilizáveis de negócio,
cálculos, validações e operações auxiliares executadas diretamente pelo PostgreSQL.

São utilizadas por:

- Views
- Procedures
- Triggers
- Relatórios
- APIs
- Dashboard
- Consultas SQL

---

### Objetivos

As Functions possuem como finalidade:

- Centralizar regras de negócio
- Evitar duplicação de código
- Melhorar desempenho
- Garantir padronização
- Facilitar manutenção
- Reduzir erros
- Apoiar auditorias

---

### Convenções

Todas as Functions seguem o padrão:

```text
fn_<nome>
```

Exemplos

```text
fn_calcular_saldo
fn_validar_cpf
fn_calcular_icb
fn_formatar_documento
```

---

### Classificação

As Functions estão organizadas por categoria:

- Utilitárias
- Financeiras
- Comerciais
- Fiscais
- Turismo
- Bike Tour
- Recursos Humanos
- Auditoria
- Governança
- Segurança
- LGPD
- Sistema

---

### Estrutura da Documentação

Cada Function documenta:

- Nome
- Objetivo
- Categoria
- Parâmetros
- Tipo de retorno
- Dependências
- Observações

---

## Functions Utilitárias

---

## fn_uuid

### Descrição

Retorna UUID para novos registros.

### Retorno

UUID

---

## fn_now_brasil

### Descrição

Retorna data e hora considerando o fuso horário do Brasil.

### Retorno

TIMESTAMP

---

## fn_normalizar_texto

### Descrição

Remove acentos, espaços duplicados e converte texto para padrão.

### Retorno

TEXT

---

## fn_remover_caracteres_especiais

### Descrição

Remove caracteres inválidos.

---

## fn_formatar_documento

### Descrição

Formata CPF, CNPJ e demais documentos.

---

## Functions Financeiras

---

## fn_calcular_saldo

### Descrição

Calcula saldo atualizado de uma conta financeira.

### Retorno

NUMERIC

---

## fn_calcular_fluxo_caixa

### Descrição

Calcula saldo do fluxo de caixa.

---

## fn_calcular_dre

### Descrição

Calcula indicadores da Demonstração do Resultado.

---

## fn_calcular_balancete

### Descrição

Calcula saldo contábil consolidado.

---

## fn_calcular_ticket_medio

### Descrição

Calcula ticket médio de vendas.

---

## fn_calcular_lucro

### Descrição

Calcula lucro líquido.

---

## fn_calcular_markup

### Descrição

Calcula percentual de markup.

---

## fn_calcular_margem

### Descrição

Calcula margem operacional.

---

## Functions Comerciais

---

## fn_total_vendas_cliente

### Descrição

Retorna o valor total vendido para um cliente.

---

## fn_total_pedidos

### Descrição

Retorna quantidade de pedidos.

---

## fn_total_clientes_ativos

### Descrição

Retorna número de clientes ativos.

---

## fn_calcular_comissao

### Descrição

Calcula comissão do vendedor.

---

## Functions Fiscais

---

## fn_calcular_simples

### Descrição

Calcula impostos do Simples Nacional.

---

## fn_calcular_iss

### Descrição

Calcula ISS.

---

## fn_calcular_pis

### Descrição

Calcula PIS.

---

## fn_calcular_cofins

### Descrição

Calcula COFINS.

---

## fn_calcular_irpj

### Descrição

Calcula IRPJ.

---

## fn_calcular_csll

### Descrição

Calcula CSLL.

---

## Functions Turismo

---

## fn_calcular_valor_pacote

### Descrição

Calcula valor final do pacote turístico.

---

## fn_calcular_desconto

### Descrição

Calcula desconto aplicado.

---

## fn_disponibilidade_pacote

### Descrição

Retorna disponibilidade.

---

## fn_total_reservas

### Descrição

Retorna quantidade de reservas.

---

## Functions Bike Tour

---

## fn_calcular_pontuacao

### Descrição

Calcula pontuação do participante.

---

## fn_calcular_classificacao

### Descrição

Calcula classificação final.

---

## fn_total_participantes

### Descrição

Retorna total de participantes.

---

## Functions RH

---

## fn_calcular_salario

### Descrição

Calcula salário líquido.

---

## fn_calcular_ferias

### Descrição

Calcula férias.

---

## fn_calcular_13

### Descrição

Calcula décimo terceiro.

---

## fn_calcular_horas_extras

### Descrição

Calcula horas extras.

---

## Functions Auditoria

---

## fn_calcular_score

### Descrição

Calcula score técnico.

---

## fn_calcular_icb

### Descrição

Calcula Índice de Conformidade do Banco.

---

## fn_total_erros

### Descrição

Retorna quantidade de erros encontrados.

---

## fn_total_alertas

### Descrição

Retorna quantidade de alertas.

---

## fn_percentual_documentacao

### Descrição

Calcula cobertura de documentação.

---

## Functions Governança

---

## fn_versao_atual

### Descrição

Retorna versão atual do banco.

---

## fn_release_atual

### Descrição

Retorna release instalada.

---

## fn_total_migracoes

### Descrição

Retorna quantidade de migrações.

---

## fn_metadata_objeto

### Descrição

Consulta catálogo de metadados.

---

## Functions Segurança

---

## fn_hash_senha

### Descrição

Calcula hash seguro da senha.

---

## fn_validar_permissao

### Descrição

Valida permissões do usuário.

---

## fn_usuario_admin

### Descrição

Verifica privilégios administrativos.

---

## Functions LGPD

---

## fn_anonimizar_nome

### Descrição

Anonimiza nomes.

---

## fn_anonimizar_email

### Descrição

Anonimiza e-mails.

---

## fn_mascarar_documento

### Descrição

Oculta parcialmente documentos.

---

## fn_mascarar_telefone

### Descrição

Oculta parcialmente telefones.

---

## Functions Sistema

---

## fn_health_check

### Descrição

Executa verificações gerais do banco.

---

## fn_database_size

### Descrição

Retorna tamanho do banco.

---

## fn_schema_size

### Descrição

Retorna tamanho do schema.

---

## fn_table_size

### Descrição

Retorna tamanho da tabela.

---

## fn_index_size

### Descrição

Retorna tamanho dos índices.

---

### Boas Práticas

Todas as Functions deverão:

- possuir COMMENT ON FUNCTION
- utilizar nomenclatura padronizada
- possuir tratamento de exceções quando necessário
- evitar efeitos colaterais
- ser determinísticas quando possível
- registrar versão
- possuir documentação técnica

---

### Dependências

As Functions podem ser utilizadas por:

- Procedures
- Views
- Triggers
- Materialized Views
- APIs
- Relatórios

---

## Estatísticas Previstas

| Categoria          |        Quantidade |
| ------------------ | ----------------: |
| Utilitárias        |                25 |
| Financeiras        |                30 |
| Comerciais         |                15 |
| Fiscais            |                20 |
| Turismo            |                20 |
| Bike Tour          |                10 |
| RH                 |                15 |
| Auditoria          |                20 |
| Governança         |                15 |
| Segurança          |                10 |
| LGPD               |                10 |
| Sistema            |                15 |
| **Total Estimado** | **205 Functions** |

---

## 6.13 Triggers

Os Triggers do WMA Travel ERP automatizam regras críticas do banco de dados,
garantindo integridade, auditoria, rastreabilidade e sincronização dos dados.

Os gatilhos são executados automaticamente em resposta a eventos de INSERT, UPDATE, DELETE e TRUNCATE.

---

### Objetivos

Os Triggers possuem como objetivos:

- Automatizar processos
- Garantir integridade
- Registrar auditoria
- Atualizar timestamps
- Controlar versões
- Validar regras de negócio
- Evitar inconsistências
- Sincronizar dados
- Manter histórico

---

### Convenções

Todos os Triggers seguem a convenção:

```text
tg_<evento>_<objeto>
```

Exemplos

```text
tg_bi_cliente
tg_ai_cliente
tg_bu_cliente
tg_au_cliente
tg_bd_cliente
tg_ad_cliente
```

Legenda

```text
bi = BEFORE INSERT
ai = AFTER INSERT

bu = BEFORE UPDATE
au = AFTER UPDATE

bd = BEFORE DELETE
ad = AFTER DELETE
```

---

### Estrutura da Documentação

Cada Trigger documenta:

- Nome
- Evento
- Tabela
- Momento
- Function executada
- Objetivo
- Observações

---

### Classificação

Os Triggers estão organizados em:

- Auditoria
- Controle de Datas
- Controle de Versão
- Exclusão Lógica
- Financeiro
- Comercial
- Fiscal
- Turismo
- Bike Tour
- Recursos Humanos
- Governança
- Segurança
- Sistema

---

## Triggers de Auditoria

---

## tg_bi_auditoria

### Evento

BEFORE INSERT

### Objetivo

Inicializar informações de auditoria.

### Campos Atualizados

- created_at
- created_by
- versao

---

## tg_bu_auditoria

### Evento

BEFORE UPDATE

### Objetivo

Atualizar informações de modificação.

### Campos Atualizados

- updated_at
- updated_by
- versao

---

## tg_bd_auditoria

### Evento

BEFORE DELETE

### Objetivo

Registrar tentativa de exclusão.

---

## tg_ad_log

### Evento

AFTER DELETE

### Objetivo

Registrar exclusão em log.

---

## Triggers de Controle de Datas

---

## tg_created_at

### Objetivo

Preencher automaticamente:

```text
created_at
```

---

## tg_updated_at

### Objetivo

Atualizar automaticamente:

```text
updated_at
```

---

## tg_deleted_at

### Objetivo

Registrar data da exclusão lógica.

---

## Triggers de Controle de Versão

---

## tg_incrementar_versao

### Objetivo

Incrementar automaticamente a coluna:

```text
versao
```

Sempre que ocorrer UPDATE.

---

## Triggers de Exclusão Lógica

---

## tg_soft_delete

### Objetivo

Converter DELETE físico em DELETE lógico.

### Campos

- deleted_at
- deleted_by

---

## Triggers Financeiros

---

## tg_fluxo_caixa

### Evento

AFTER INSERT

### Objetivo

Atualizar saldo do Fluxo de Caixa.

---

## tg_contas_receber

### Objetivo

Atualizar posição financeira.

---

## tg_contas_pagar

### Objetivo

Atualizar compromissos financeiros.

---

## tg_recalcular_saldo

### Objetivo

Recalcular saldo bancário.

---

## Triggers Comerciais

---

## tg_cliente_status

### Objetivo

Atualizar status do cliente.

---

## tg_venda_total

### Objetivo

Atualizar valor total da venda.

---

## tg_comissao

### Objetivo

Recalcular comissão.

---

## Triggers Fiscais

---

## tg_nota_fiscal

### Objetivo

Atualizar informações fiscais.

---

## tg_impostos

### Objetivo

Recalcular tributos.

---

## Triggers Turismo

---

## tg_reserva

### Objetivo

Atualizar disponibilidade.

---

## tg_pacote

### Objetivo

Atualizar vagas.

---

## tg_voucher

### Objetivo

Gerar voucher automaticamente.

---

## Triggers Bike Tour

---

## tg_inscricao

### Objetivo

Atualizar número de participantes.

---

## tg_checkin

### Objetivo

Registrar presença.

---

## tg_classificacao

### Objetivo

Atualizar ranking.

---

## Triggers Recursos Humanos

---

## tg_ponto

### Objetivo

Atualizar banco de horas.

---

## tg_folha

### Objetivo

Atualizar folha de pagamento.

---

## Triggers Governança

---

## tg_metadata

### Objetivo

Atualizar catálogo de metadados.

---

## tg_release

### Objetivo

Registrar nova versão.

---

## tg_migracao

### Objetivo

Registrar migração executada.

---

## Triggers Segurança

---

## tg_log_login

### Objetivo

Registrar autenticação.

---

## tg_log_permissao

### Objetivo

Registrar alterações de permissões.

---

## tg_log_role

### Objetivo

Registrar alterações de Roles.

---

## Triggers Sistema

---

## tg_health_check

### Objetivo

Atualizar indicadores técnicos.

---

## tg_dashboard

### Objetivo

Atualizar indicadores do Dashboard.

---

## tg_cache

### Objetivo

Invalidar cache quando necessário.

---

## Ordem de Execução

Fluxo padrão

```text
INSERT

↓

BEFORE INSERT

↓

Validação

↓

Inserção

↓

AFTER INSERT

↓

Auditoria

↓

Atualização Dashboard

↓

Log
```

---

## Padrões Obrigatórios

Todos os Triggers deverão:

- utilizar Functions documentadas
- possuir COMMENT ON TRIGGER
- possuir COMMENT ON FUNCTION
- registrar versão
- respeitar transações
- evitar processamento pesado
- não executar SQL desnecessário

---

### Dependências

Os Triggers dependem de:

- Functions
- Procedures
- Views
- Sequences
- Constraints

---

### Estatísticas Previstas

| Categoria          |       Quantidade |
| ------------------ | ---------------: |
| Auditoria          |               18 |
| Datas              |                8 |
| Versão             |                6 |
| Exclusão Lógica    |                6 |
| Financeiro         |               20 |
| Comercial          |               12 |
| Fiscal             |               10 |
| Turismo            |               12 |
| Bike Tour          |                8 |
| RH                 |               10 |
| Governança         |                8 |
| Segurança          |                8 |
| Sistema            |               10 |
| **Total Estimado** | **136 Triggers** |

---

### Benefícios

A utilização dos Triggers proporciona:

- Integridade automática
- Auditoria completa
- Rastreabilidade
- Consistência
- Padronização
- Segurança
- Alta confiabilidade
- Menor duplicação de código
- Melhor desempenho operacional

---

## 6.14 Índices (Indexes)

Os Índices do WMA Travel ERP são responsáveis por otimizar o acesso aos dados,
reduzir o tempo de resposta das consultas e garantir desempenho adequado para operações transacionais e analíticas.

A estratégia de indexação foi projetada considerando um ambiente corporativo com crescimento contínuo do volume de dados.

---

### Objetivos

A política de indexação possui os seguintes objetivos:

- Melhorar desempenho das consultas
- Otimizar JOINs
- Otimizar ORDER BY
- Otimizar GROUP BY
- Acelerar filtros (WHERE)
- Garantir integridade referencial
- Reduzir Full Table Scan
- Apoiar Business Intelligence
- Melhorar desempenho das APIs

---

### Convenções

Todos os índices seguem o padrão:

```text
idx_<tabela>_<coluna>

idx_cliente_nome

idx_reserva_data

idx_fluxo_caixa_data
```

Índices únicos:

```text
uk_<tabela>_<coluna>
```

Exemplo

```text
uk_empresa_cnpj
```

Índices compostos:

```text
idx_<tabela>_<campo1>_<campo2>
```

Exemplo

```text
idx_reserva_cliente_data
```

---

## Tipos Utilizados

## PRIMARY KEY

Responsável pela identificação única do registro.

Exemplo

```sql
PRIMARY KEY (id_cliente)
```

---

## UNIQUE INDEX

Impede duplicidade.

Exemplos

- CPF
- CNPJ
- E-mail
- Código interno

---

## FOREIGN KEY INDEX

Todo relacionamento deverá possuir índice correspondente.

Exemplo

```text
cliente_id

empresa_id

usuario_id
```

---

## INDEX SIMPLES

Utilizado em filtros frequentes.

Exemplo

```sql
CREATE INDEX idx_cliente_nome
ON cliente(nome);
```

---

## ÍNDICE COMPOSTO

Utilizado quando múltiplas colunas são consultadas simultaneamente.

Exemplo

```sql
(cliente_id,data_reserva)
```

---

## ÍNDICE PARCIAL

Utilizado quando apenas parte da tabela é consultada.

Exemplo

```sql
WHERE deleted_at IS NULL
```

---

## ÍNDICE FUNCIONAL

Utilizado para funções SQL.

Exemplo

```sql
LOWER(nome)
```

---

## GIN INDEX

Utilizado para:

- JSONB
- Full Text Search
- Arrays

---

## GiST INDEX

Utilizado para:

- Geolocalização
- Distâncias
- Dados espaciais

---

## BRIN INDEX

Utilizado em tabelas muito grandes.

Exemplo

Movimentações financeiras.

---

## Estratégia de Indexação

Cada tabela deverá possuir:

- Primary Key
- Índices das Foreign Keys
- Índices para campos pesquisados
- Índices para ORDER BY
- Índices para GROUP BY
- Índices compostos quando necessário

---

## Índices Obrigatórios

## Empresa

```text
id_empresa

cnpj

razao_social
```

---

## Cliente

```text
id_cliente

cpf_cnpj

email

telefone

cidade

status
```

---

## Fornecedor

```text
id_fornecedor

cnpj

nome
```

---

## Usuário

```text
id_usuario

login

email

status
```

---

## Fluxo de Caixa

```text
data_movimento

empresa_id

conta_id

natureza

status
```

---

## Contas a Receber

```text
cliente_id

vencimento

status
```

---

## Contas a Pagar

```text
fornecedor_id

vencimento

status
```

---

## Reserva

```text
cliente_id

pacote_id

data_reserva

status
```

---

## Pacote Turístico

```text
destino_id

categoria

status
```

---

## Evento Bike

```text
data_evento

cidade

status
```

---

## Índices Compostos

Exemplos

```text
cliente_id + data

empresa_id + status

empresa_id + created_at

usuario_id + status

evento_id + participante_id
```

---

## Índices Únicos

Exemplos

```text
CPF

CNPJ

E-mail

Código

Número da Nota Fiscal
```

---

## Índices Funcionais

Exemplos

```sql
LOWER(nome)

UPPER(sigla)

LOWER(email)
```

---

## Índices Parciais

Exemplo

```sql
WHERE deleted_at IS NULL
```

Aplicações

- Clientes ativos
- Produtos ativos
- Reservas ativas
- Eventos ativos

---

## Índices JSONB

Utilizados em:

- Configurações
- Logs
- Integrações
- Auditoria

Tipo

```text
GIN
```

---

## Índices Geográficos

Utilizados em:

- Turismo
- Bike Tour

Tipo

```text
GiST
```

---

## Auditoria dos Índices

O Framework DBA valida automaticamente:

- Índices ausentes
- Índices duplicados
- Índices não utilizados
- Índices inválidos
- Índices de Foreign Keys
- Índices de Performance

---

## Indicadores Monitorados

- Número total de índices
- Índices utilizados
- Índices duplicados
- Índices inválidos
- Índices sem utilização
- Índices recomendados
- Cobertura de Foreign Keys

---

### Boas Práticas

Todos os índices deverão:

- possuir COMMENT ON INDEX
- utilizar nomenclatura padronizada
- evitar redundância
- possuir documentação
- ser monitorados periodicamente
- possuir justificativa técnica

---

### Estatísticas Previstas

| Categoria           |      Quantidade |
| ------------------- | --------------: |
| Primary Keys        |             190 |
| Foreign Key Indexes |             142 |
| Índices Simples     |             260 |
| Índices Compostos   |             120 |
| Índices Únicos      |              70 |
| Índices Funcionais  |              30 |
| Índices Parciais    |              40 |
| Índices GIN         |              15 |
| Índices GiST        |              10 |
| Índices BRIN        |               8 |
| **Total Estimado**  | **885 Índices** |

---

### Benefícios

A estratégia de indexação proporciona:

- Consultas mais rápidas
- Melhor desempenho do PostgreSQL
- Redução de I/O
- Melhor utilização da memória
- Otimização dos planos de execução
- Maior escalabilidade
- Melhor desempenho das APIs
- Melhor desempenho do Power BI
- Base para auditoria automática

---

## 6.15 Chaves Estrangeiras (Foreign Keys)

As Chaves Estrangeiras (Foreign Keys) garantem a integridade referencial do banco de dados,
assegurando que os relacionamentos entre tabelas permaneçam consistentes durante toda a vida útil do sistema.

Todas as Foreign Keys do WMA Travel ERP seguem padrões corporativos de nomenclatura, indexação e documentação.

---

### Objetivos

A estratégia de Foreign Keys possui os seguintes objetivos:

- Garantir integridade referencial
- Evitar registros órfãos
- Padronizar relacionamentos
- Melhorar desempenho dos JOINs
- Facilitar manutenção
- Suportar auditoria automática
- Apoiar certificação do banco

---

### Convenções

Todas as Foreign Keys seguem o padrão:

```text
fk_<tabela_origem>_<tabela_destino>
```

Exemplos

```text
fk_cliente_empresa

fk_reserva_cliente

fk_fluxo_caixa_plano_conta

fk_usuario_perfil
```

---

### Estrutura da Documentação

Cada Foreign Key documenta:

- Nome
- Tabela origem
- Coluna origem
- Tabela destino
- Coluna destino
- Cardinalidade
- ON UPDATE
- ON DELETE
- Índice associado
- Observações

---

## Cardinalidades

O modelo utiliza os seguintes relacionamentos.

## Um para Um (1:1)

```text
empresa
      │
      │
      ▼
configuracao_empresa
```

---

## Um para Muitos (1:N)

```text
cliente
      │
      ├──────────────┐
      ▼              ▼

reserva      contas_receber
```

---

## Muitos para Muitos (N:N)

Implementado através de tabela intermediária.

```text
usuario

     │

usuario_perfil

     │

perfil
```

---

## Políticas de Integridade

As Foreign Keys seguem as seguintes regras.

## ON UPDATE

Padrão adotado

```sql
ON UPDATE CASCADE
```

Quando permitido.

---

## ON DELETE

Dependendo da natureza do relacionamento:

### RESTRICT

Impedir exclusão.

```sql
ON DELETE RESTRICT
```

---

### CASCADE

Excluir registros dependentes.

```sql
ON DELETE CASCADE
```

---

### SET NULL

Manter histórico.

```sql
ON DELETE SET NULL
```

---

### NO ACTION

Utilizado em situações específicas.

---

## Relacionamentos Administrativos

### Empresa

Relacionamentos principais

```text
empresa

↓

usuario

↓

departamento

↓

colaborador

↓

configuracao
```

---

### Usuário

Relacionamentos

```text
usuario

↓

perfil

↓

usuario_perfil

↓

log_acesso
```

---

## Relacionamentos Financeiros

### Plano de Contas

```text
plano_conta

↓

lancamento_financeiro

↓

fluxo_caixa
```

---

### Contas a Receber

```text
cliente

↓

contas_receber

↓

recebimento
```

---

### Contas a Pagar

```text
fornecedor

↓

contas_pagar

↓

pagamento
```

---

## Relacionamentos Comerciais

```text
cliente

↓

proposta

↓

pedido

↓

venda
```

---

## Relacionamentos Fiscais

```text
empresa

↓

nota_fiscal

↓

tributo

↓

apuracao
```

---

## Relacionamentos Turismo

```text
cliente

↓

reserva

↓

pacote

↓

destino

↓

hotel

↓

voo
```

---

## Relacionamentos Bike Tour

```text
evento

↓

inscricao

↓

participante

↓

resultado
```

---

## Relacionamentos Recursos Humanos

```text
colaborador

↓

cargo

↓

departamento

↓

folha_pagamento
```

---

## Relacionamentos Auditoria

```text
execucao

↓

resultado

↓

score

↓

certificacao
```

---

## Relacionamentos Governança

```text
release

↓

migracao

↓

metadata

↓

versionamento
```

---

### Índices Obrigatórios

Toda Foreign Key deverá possuir índice correspondente.

Exemplo

```sql
CREATE INDEX idx_cliente_empresa
ON cliente(id_empresa);
```

---

### Auditoria Automática

O Framework DBA valida automaticamente:

- Foreign Keys ausentes
- Foreign Keys inválidas
- Foreign Keys sem índice
- Foreign Keys duplicadas
- Integridade referencial
- Cardinalidade

---

### Boas Práticas

Todas as Foreign Keys deverão:

- possuir COMMENT ON CONSTRAINT
- possuir índice correspondente
- utilizar nomenclatura padronizada
- respeitar regras de negócio
- evitar CASCADE desnecessário
- ser documentadas

---

### Dependências

As Foreign Keys suportam:

- Views
- Procedures
- Functions
- Triggers
- APIs
- Dashboards

---

### Estatísticas Previstas

| Categoria              | Quantidade |
| ---------------------- | ---------: |
| Relacionamentos 1:1    |         18 |
| Relacionamentos 1:N    |        110 |
| Relacionamentos N:N    |         14 |
| Foreign Keys Totais    |        142 |
| Foreign Keys Indexadas |        142 |
| Cobertura Esperada     |       100% |

---

### Benefícios

A utilização adequada das Foreign Keys proporciona:

- Integridade dos dados
- Melhor desempenho dos JOINs
- Segurança nas exclusões
- Consistência das informações
- Facilidade de manutenção
- Auditoria automatizada
- Certificação técnica do banco

---

## Certificação

Para certificação do banco, todas as Foreign Keys deverão atender aos seguintes critérios:

| Critério                 | Obrigatório |
| ------------------------ | :---------: |
| Constraint criada        |     Sim     |
| Índice correspondente    |     Sim     |
| COMMENT ON CONSTRAINT    |     Sim     |
| Nomenclatura padronizada |     Sim     |
| Integridade validada     |     Sim     |
| Auditoria aprovada       |     Sim     |

---

## 6.16 Constraints

As Constraints (Restrições) garantem a integridade estrutural e lógica do banco de dados,
impedindo o armazenamento de dados inválidos e assegurando que todas as regras fundamentais do modelo sejam respeitadas.

No WMA Travel ERP, todas as Constraints seguem um padrão único de nomenclatura, documentação e auditoria.

---

### Objetivos

As Constraints possuem os seguintes objetivos:

- Garantir integridade dos dados
- Evitar inconsistências
- Validar regras de negócio
- Padronizar o banco de dados
- Facilitar auditorias
- Reduzir erros de aplicação
- Melhorar a qualidade das informações

---

## Tipos de Constraints

O banco utiliza os seguintes tipos:

- PRIMARY KEY
- FOREIGN KEY
- UNIQUE
- CHECK
- NOT NULL
- DEFAULT
- EXCLUDE

---

### Convenções

Todas as Constraints seguem nomenclatura padronizada.

## Primary Key

```text
pk_<tabela>
```

Exemplo

```text
pk_cliente
pk_empresa
pk_usuario
```

---

## Foreign Key

```text
fk_<origem>_<destino>
```

Exemplo

```text
fk_cliente_empresa
fk_reserva_cliente
```

---

## Unique

```text
uk_<tabela>_<campo>
```

Exemplo

```text
uk_empresa_cnpj

uk_usuario_email
```

---

## Check

```text
ck_<tabela>_<campo>
```

Exemplo

```text
ck_cliente_status

ck_lancamento_valor
```

---

## Default

Os valores padrão seguem documentação própria.

Exemplo

```sql
DEFAULT CURRENT_TIMESTAMP

DEFAULT 1

DEFAULT TRUE
```

---

## PRIMARY KEY

Toda tabela possui exatamente uma chave primária.

Características

- única
- obrigatória
- indexada automaticamente
- documentada

Exemplo

```sql
CONSTRAINT pk_cliente

PRIMARY KEY(id_cliente)
```

---

## FOREIGN KEY

As Foreign Keys garantem integridade referencial.

Exemplo

```sql
CONSTRAINT fk_cliente_empresa

FOREIGN KEY(id_empresa)

REFERENCES empresa(id_empresa)
```

---

## UNIQUE

Impede duplicidade de informações.

Aplicações

- CPF
- CNPJ
- E-mail
- Login
- Código interno

Exemplo

```sql
CONSTRAINT uk_empresa_cnpj

UNIQUE(cnpj)
```

---

## CHECK

Valida regras específicas.

Exemplo

```sql
valor >= 0
```

---

Outro exemplo

```sql
status

IN

('ATIVO','INATIVO')
```

---

Exemplo financeiro

```sql
saldo >= 0
```

---

Exemplo de percentual

```sql
desconto

BETWEEN 0 AND 100
```

---

## NOT NULL

Campos obrigatórios.

Exemplos

```text
id_empresa

created_at

created_by

nome

status
```

---

## DEFAULT

Valores automáticos.

Exemplos

```sql
CURRENT_TIMESTAMP

TRUE

FALSE

0

1
```

---

## EXCLUDE

Utilizado em situações especiais.

Exemplos

- reservas
- agenda
- conflitos de horários

---

## Constraints Financeiras

Principais validações

```text
Valor >= 0

Saldo >= 0

Data pagamento >= vencimento

Competência válida
```

---

## Constraints Comerciais

```text
CPF único

Email único

Cliente ativo
```

---

## Constraints Fiscais

```text
CNPJ válido

Inscrição Estadual

Número NF único
```

---

## Constraints Turismo

```text
Data retorno

>

Data saída
```

---

```text
Quantidade vagas

>=

Quantidade reservas
```

---

## Constraints Bike Tour

```text
Data evento válida

Idade mínima

Capacidade máxima
```

---

## Constraints Recursos Humanos

```text
Salário > 0

Carga horária > 0
```

---

## Constraints Segurança

```text
Senha obrigatória

Perfil obrigatório

Usuário ativo
```

---

## Auditoria das Constraints

O Framework DBA verifica automaticamente:

- Constraints inexistentes
- Constraints duplicadas
- Constraints inválidas
- Constraints sem documentação
- Constraints desabilitadas
- Constraints órfãs

---

### Dependências

As Constraints são utilizadas por:

- Procedures
- Functions
- Triggers
- APIs
- Framework de Auditoria
- Framework de Certificação

---

### Boas Práticas

Todas as Constraints deverão:

- possuir COMMENT ON CONSTRAINT
- utilizar nomenclatura padronizada
- possuir documentação
- ser auditadas automaticamente
- respeitar regras de negócio
- evitar redundância

---

### Estatísticas Previstas

| Constraint         |   Quantidade Estimada |
| ------------------ | --------------------: |
| PRIMARY KEY        |                   190 |
| FOREIGN KEY        |                   142 |
| UNIQUE             |                    72 |
| CHECK              |                   118 |
| NOT NULL           |                 1.450 |
| DEFAULT            |                   680 |
| EXCLUDE            |                     6 |
| **Total Estimado** | **2.658 Constraints** |

---

## Critérios para Certificação

Todas as Constraints deverão atender aos seguintes requisitos.

| Critério                  | Obrigatório |
| ------------------------- | :---------: |
| Nome padronizado          |     Sim     |
| COMMENT ON                |     Sim     |
| Documentada               |     Sim     |
| Auditada                  |     Sim     |
| Validada                  |     Sim     |
| Compatível com PostgreSQL |     Sim     |

---

### Benefícios

A utilização das Constraints proporciona:

- Integridade dos dados
- Segurança
- Confiabilidade
- Padronização
- Facilidade de manutenção
- Melhor desempenho
- Base para auditorias automáticas
- Certificação técnica do banco

---

## 6.17 Sequences

As Sequences são objetos responsáveis pela geração automática de valores numéricos sequenciais utilizados principalmente
nas chaves primárias das tabelas do WMA Travel ERP.

Embora o PostgreSQL possua suporte ao padrão `GENERATED AS IDENTITY`,
o projeto documenta todas as Sequences para garantir rastreabilidade, padronização e auditoria.

---

### Objetivos

As Sequences possuem os seguintes objetivos:

- Gerar identificadores únicos
- Garantir integridade das chaves primárias
- Evitar colisão de identificadores
- Suportar alta concorrência
- Facilitar replicação
- Padronizar geração de IDs
- Simplificar manutenção

---

### Convenções

Todas as Sequences seguem o padrão:

```text
seq_<tabela>
```

Exemplos

```text
seq_empresa
seq_cliente
seq_usuario
seq_fornecedor
seq_reserva
seq_evento
```

---

### Estrutura da Documentação

Cada Sequence documenta:

- Nome
- Tabela associada
- Coluna utilizada
- Valor inicial
- Incremento
- Cache
- Ciclo
- Observações

---

## Configuração Padrão

Todas as Sequences seguem a configuração abaixo.

| Parâmetro    |  Valor |
| ------------ | -----: |
| START WITH   |      1 |
| INCREMENT BY |      1 |
| MINVALUE     |      1 |
| MAXVALUE     | BIGINT |
| CACHE        |    100 |
| CYCLE        |    NÃO |

---

## Exemplo

```sql
CREATE SEQUENCE seq_cliente
START WITH 1
INCREMENT BY 1
MINVALUE 1
CACHE 100
NO CYCLE;
```

---

## Associação com a Tabela

```sql
ALTER TABLE cliente
ALTER COLUMN id_cliente
SET DEFAULT nextval('seq_cliente');
```

---

## Sequences Administrativas

| Sequence         | Tabela       |
| ---------------- | ------------ |
| seq_empresa      | empresa      |
| seq_usuario      | usuario      |
| seq_departamento | departamento |
| seq_perfil       | perfil       |
| seq_parametro    | parametro    |

---

## Sequences Financeiras

| Sequence          | Tabela                |
| ----------------- | --------------------- |
| seq_plano_conta   | plano_conta           |
| seq_fluxo_caixa   | fluxo_caixa           |
| seq_conta_receber | conta_receber         |
| seq_conta_pagar   | conta_pagar           |
| seq_lancamento    | lancamento_financeiro |

---

## Sequences Comerciais

| Sequence       | Tabela     |
| -------------- | ---------- |
| seq_cliente    | cliente    |
| seq_fornecedor | fornecedor |
| seq_proposta   | proposta   |
| seq_pedido     | pedido     |
| seq_venda      | venda      |

---

## Sequences Fiscais

| Sequence     | Tabela          |
| ------------ | --------------- |
| seq_nf       | nota_fiscal     |
| seq_apuracao | apuracao_fiscal |
| seq_tributo  | tributo         |

---

## Sequences Turismo

| Sequence    | Tabela  |
| ----------- | ------- |
| seq_destino | destino |
| seq_pacote  | pacote  |
| seq_reserva | reserva |
| seq_hotel   | hotel   |
| seq_voo     | voo     |

---

## Sequences Bike Tour

| Sequence         | Tabela       |
| ---------------- | ------------ |
| seq_evento       | evento       |
| seq_inscricao    | inscricao    |
| seq_participante | participante |
| seq_resultado    | resultado    |

---

## Sequences Recursos Humanos

| Sequence        | Tabela          |
| --------------- | --------------- |
| seq_colaborador | colaborador     |
| seq_cargo       | cargo           |
| seq_folha       | folha_pagamento |

---

## Sequences Auditoria

| Sequence         | Tabela                 |
| ---------------- | ---------------------- |
| seq_execucao     | auditoria.execucao     |
| seq_resultado    | auditoria.resultado    |
| seq_score        | auditoria.score        |
| seq_certificacao | auditoria.certificacao |

---

## Sequences Governança

| Sequence     | Tabela   |
| ------------ | -------- |
| seq_release  | release  |
| seq_migracao | migracao |
| seq_metadata | metadata |

---

## Estratégia de Crescimento

As Sequences utilizam o tipo `BIGINT`.

Capacidade aproximada:

```text
9.223.372.036.854.775.807 registros
```

Este limite é suficiente para décadas de operação.

---

## Cache

O cache reduz acessos ao catálogo do PostgreSQL.

Valor recomendado:

```text
CACHE 100
```

Em tabelas de alta movimentação poderá ser utilizado:

```text
CACHE 500
```

ou

```text
CACHE 1000
```

---

## Ciclo

O parâmetro `CYCLE` permanece desabilitado.

```text
NO CYCLE
```

Nunca reutilizar identificadores.

---

## Identity Columns

Sempre que possível, novas tabelas deverão utilizar:

```sql
GENERATED ALWAYS AS IDENTITY
```

ou

```sql
GENERATED BY DEFAULT AS IDENTITY
```

A documentação continuará registrando a Sequence interna criada pelo PostgreSQL.

---

## Auditoria das Sequences

O Framework DBA verifica automaticamente:

- Sequences órfãs
- Sequences não utilizadas
- Sequências duplicadas
- Valor atual
- Último valor utilizado
- Próximo valor
- Overflow
- Configuração inadequada

---

### Boas Práticas

Todas as Sequences deverão:

- possuir COMMENT ON SEQUENCE
- possuir nomenclatura padronizada
- utilizar BIGINT
- utilizar CACHE
- não utilizar CYCLE
- estar documentadas
- ser monitoradas

---

### Dependências

As Sequences são utilizadas por:

- Tabelas
- Procedures
- Functions
- Scripts de carga
- Framework de Auditoria

---

### Estatísticas Previstas

| Categoria                 |        Quantidade |
| ------------------------- | ----------------: |
| Sequences Administrativas |                12 |
| Sequences Financeiras     |                20 |
| Sequences Comerciais      |                15 |
| Sequences Fiscais         |                10 |
| Sequences Turismo         |                18 |
| Sequences Bike Tour       |                10 |
| Sequences RH              |                10 |
| Sequences Auditoria       |                 8 |
| Sequences Governança      |                 6 |
| **Total Estimado**        | **109 Sequences** |

---

### Critérios para Certificação

Todas as Sequences deverão atender aos seguintes requisitos.

| Critério            | Obrigatório |
| ------------------- | :---------: |
| Nome padronizado    |     Sim     |
| COMMENT ON SEQUENCE |     Sim     |
| BIGINT              |     Sim     |
| CACHE configurado   |     Sim     |
| NO CYCLE            |     Sim     |
| Documentada         |     Sim     |
| Auditada            |     Sim     |

---

### Benefícios

A utilização padronizada das Sequences proporciona:

- Identificadores únicos
- Alto desempenho
- Escalabilidade
- Facilidade de manutenção
- Integridade estrutural
- Compatibilidade com PostgreSQL
- Base para auditorias automáticas
- Suporte à certificação do banco

---

## 6.18 Materialized Views

As Materialized Views (Visões Materializadas) são utilizadas para armazenar previamente o resultado de consultas complexas,
reduzindo o tempo de resposta de dashboards, indicadores, relatórios e análises estratégicas.

Diferentemente das Views convencionais, os dados são persistidos fisicamente e
atualizados através do comando `REFRESH MATERIALIZED VIEW`.

---

### Objetivos

As Materialized Views possuem os seguintes objetivos:

- Melhorar desempenho
- Reduzir tempo de resposta
- Apoiar Business Intelligence
- Consolidar indicadores
- Diminuir processamento repetitivo
- Facilitar auditorias
- Otimizar consultas complexas

---

### Convenções

Todas as Materialized Views seguem o padrão:

```text
mv_<nome>
```

Exemplos

```text
mv_fluxo_caixa
mv_dre
mv_dashboard_financeiro
mv_indicadores_vendas
mv_auditoria_icb
```

---

### Estrutura da Documentação

Cada Materialized View documenta:

- Nome
- Objetivo
- Fonte dos dados
- Frequência de atualização
- Dependências
- Índices
- Observações

---

## Estratégia de Atualização

As Materialized Views poderão ser atualizadas:

- Manualmente
- Agendamento (Scheduler)
- Finalização de Processamentos
- Jobs Noturnos
- Procedures Administrativas

---

## Atualização

Exemplo

```sql
REFRESH MATERIALIZED VIEW mv_fluxo_caixa;
```

Atualização concorrente

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_fluxo_caixa;
```

---

## Materialized Views Financeiras

## mv_fluxo_caixa

### Objetivo

Consolidar movimentações financeiras por período.

### Atualização

Diária

### Origem

- fluxo_caixa
- lancamento_financeiro
- conta_bancaria

---

## mv_dre

### Objetivo

Consolidar Demonstração do Resultado.

---

## mv_balancete

### Objetivo

Consolidar Balancete Contábil.

---

## mv_indicadores_financeiros

### Objetivo

Calcular KPIs financeiros.

---

## Materialized Views Comerciais

## mv_vendas

### Objetivo

Consolidar vendas.

---

## mv_clientes

### Objetivo

Resumo dos clientes.

---

## mv_ticket_medio

### Objetivo

Calcular ticket médio.

---

## mv_comissoes

### Objetivo

Consolidar comissões.

---

## Materialized Views Fiscais

## mv_apuracao_fiscal

### Objetivo

Consolidar tributos.

---

## mv_notas_emitidas

### Objetivo

Resumo das notas fiscais.

---

## mv_obrigacoes

### Objetivo

Monitorar obrigações fiscais.

---

## Materialized Views Turismo

## mv_reservas

### Objetivo

Resumo das reservas.

---

## mv_ocupacao

### Objetivo

Taxa de ocupação.

---

## mv_destinos

### Objetivo

Destinos mais vendidos.

---

## mv_pacotes

### Objetivo

Resumo dos pacotes turísticos.

---

## Materialized Views Bike Tour

## mv_eventos

### Objetivo

Resumo dos eventos.

---

## mv_participantes

### Objetivo

Indicadores dos participantes.

---

## mv_classificacao

### Objetivo

Ranking dos eventos.

---

## Materialized Views Recursos Humanos

## mv_folha

### Objetivo

Resumo da folha.

---

## mv_colaboradores

### Objetivo

Indicadores de RH.

---

## mv_horas

### Objetivo

Banco de horas.

---

## Materialized Views Auditoria

## mv_icb

### Objetivo

Índice de Conformidade do Banco.

---

## mv_score

### Objetivo

Resumo do Score Técnico.

---

## mv_execucoes

### Objetivo

Resumo das auditorias.

---

## mv_nao_conformidades

### Objetivo

Consolidar inconsistências.

---

## Materialized Views Governança

## mv_release

### Objetivo

Resumo das versões.

---

## mv_metadata

### Objetivo

Catálogo técnico.

---

## mv_migracoes

### Objetivo

Histórico das migrações.

---

## Materialized Views Dashboard

## mv_dashboard_executivo

### Objetivo

Painel Executivo.

---

## mv_dashboard_operacional

### Objetivo

Painel Operacional.

---

## mv_dashboard_financeiro

### Objetivo

Painel Financeiro.

---

## mv_dashboard_comercial

### Objetivo

Painel Comercial.

---

## mv_dashboard_turismo

### Objetivo

Painel Turismo.

---

## mv_dashboard_bike

### Objetivo

Painel Bike Tour.

---

## Índices

Toda Materialized View deverá possuir índices adequados.

Exemplo

```sql
CREATE INDEX idx_mv_fluxo_data
ON mv_fluxo_caixa(data_movimento);
```

---

## Auditoria

O Framework DBA verifica automaticamente:

- Materialized Views inválidas
- Materialized Views desatualizadas
- Índices ausentes
- Tempo de atualização
- Dependências
- Performance

---

### Boas Práticas

Todas as Materialized Views deverão:

- possuir COMMENT ON MATERIALIZED VIEW
- possuir índices
- utilizar nomenclatura padronizada
- possuir documentação
- possuir estratégia de atualização
- possuir auditoria automática

---

### Dependências

As Materialized Views utilizam:

- Views
- Tables
- Functions
- Procedures
- Triggers

E são consumidas por:

- Dashboards
- APIs
- Power BI
- Relatórios
- Framework DBA

---

## Frequência Recomendada

| Categoria           | Frequência        |
| ------------------- | ----------------- |
| Financeiro          | A cada 15 minutos |
| Comercial           | A cada 15 minutos |
| Turismo             | A cada 30 minutos |
| Bike Tour           | A cada 30 minutos |
| Fiscal              | Diária            |
| Auditoria           | Sob demanda       |
| Governança          | Sob demanda       |
| Dashboard Executivo | Horária           |

---

### Estatísticas Previstas

| Categoria          |                Quantidade |
| ------------------ | ------------------------: |
| Financeiras        |                        12 |
| Comerciais         |                         8 |
| Fiscais            |                         6 |
| Turismo            |                         8 |
| Bike Tour          |                         6 |
| Recursos Humanos   |                         5 |
| Auditoria          |                         8 |
| Governança         |                         5 |
| Dashboards         |                        10 |
| **Total Estimado** | **68 Materialized Views** |

---

### Critérios para Certificação

Todas as Materialized Views deverão atender aos seguintes requisitos.

| Critério                           | Obrigatório |
| ---------------------------------- | :---------: |
| Nome padronizado                   |     Sim     |
| COMMENT ON MATERIALIZED VIEW       |     Sim     |
| Índices criados                    |     Sim     |
| Estratégia de atualização definida |     Sim     |
| Auditoria habilitada               |     Sim     |
| Documentação completa              |     Sim     |

---

### Benefícios

A utilização de Materialized Views proporciona:

- Alto desempenho
- Consultas rápidas
- Redução da carga no banco
- Melhor experiência do usuário
- Melhor desempenho do Power BI
- Dashboards em tempo real
- Base para indicadores estratégicos
- Suporte ao Framework de Certificação

---

## 6.19 Domínios (Domains) e Tipos Personalizados (Custom Types)

Os Domains e Custom Types são objetos reutilizáveis do PostgreSQL utilizados para padronizar tipos de dados,
reduzir redundância e garantir consistência em todo o banco de dados.

Sempre que uma mesma regra de validação for utilizada em múltiplas tabelas, deverá ser implementada através de um Domain.

---

### Objetivos

Os Domains possuem os seguintes objetivos:

- Padronizar tipos de dados
- Centralizar regras de validação
- Reduzir redundância
- Facilitar manutenção
- Garantir consistência
- Melhorar documentação
- Apoiar auditoria automática

---

### Tipos Utilizados

O projeto utiliza os seguintes objetos:

- Domains
- ENUM Types
- Composite Types
- Range Types
- Arrays
- JSONB

---

### Convenções

Todos os Domains seguem o padrão:

```text
dm_<nome>
```

Exemplos

```text
dm_cpf

dm_cnpj

dm_email

dm_telefone

dm_valor

dm_percentual
```

---

Todos os ENUM seguem o padrão:

```text
tp_<nome>
```

Exemplos

```text
tp_status

tp_pagamento

tp_documento
```

---

### Estrutura da Documentação

Cada Domain documenta:

- Nome
- Tipo Base
- Regra de Validação
- Objetivo
- Exemplos
- Observações

---

## Domains Gerais

## dm_nome

Tipo Base

```text
VARCHAR(150)
```

Validação

- Obrigatório
- Sem espaços extras
- Comprimento mínimo

---

## dm_descricao

Tipo Base

```text
TEXT
```

---

## dm_observacao

Tipo Base

```text
TEXT
```

---

## Domains Financeiros

## dm_valor

Tipo

```text
NUMERIC(18,2)
```

Validação

```text
Valor >= 0
```

---

## dm_percentual

Tipo

```text
NUMERIC(5,2)
```

Validação

```text
0 <= valor <= 100
```

---

## dm_taxa

Tipo

```text
NUMERIC(8,4)
```

---

## dm_quantidade

Tipo

```text
INTEGER
```

Validação

```text
>= 0
```

---

## Domains de Datas

## dm_data

Tipo

```text
DATE
```

---

## dm_datetime

Tipo

```text
TIMESTAMP
```

---

## dm_ano

Tipo

```text
INTEGER
```

---

## dm_mes

Tipo

```text
SMALLINT
```

Validação

```text
1 a 12
```

---

## Domains de Documentos

## dm_cpf

Tipo

```text
VARCHAR(11)
```

Validação

CPF válido.

---

## dm_cnpj

Tipo

```text
VARCHAR(14)
```

Validação

CNPJ válido.

---

## dm_ie

Inscrição Estadual.

---

## dm_passaporte

Documento internacional.

---

## Domains de Contato

## dm_email

Tipo

```text
VARCHAR(255)
```

Validação

Formato de e-mail.

---

## dm_telefone

Tipo

```text
VARCHAR(20)
```

---

## dm_cep

Tipo

```text
VARCHAR(8)
```

---

## Domains de Auditoria

## dm_usuario

Tipo

```text
BIGINT
```

---

## dm_created_at

Tipo

```text
TIMESTAMP
```

---

## dm_updated_at

Tipo

```text
TIMESTAMP
```

---

## dm_deleted_at

Tipo

```text
TIMESTAMP
```

---

## dm_versao

Tipo

```text
INTEGER
```

---

## ENUM Types

## tp_status

Valores

```text
ATIVO

INATIVO

BLOQUEADO
```

---

## tp_pagamento

Valores

```text
PIX

DINHEIRO

CARTAO

BOLETO

TRANSFERENCIA
```

---

## tp_documento

Valores

```text
CPF

CNPJ

PASSAPORTE
```

---

## tp_sexo

Valores

```text
M

F

OUTRO
```

---

## tp_sim_nao

Valores

```text
SIM

NAO
```

---

## tp_tipo_cliente

Valores

```text
PF

PJ
```

---

## tp_tipo_empresa

Valores

```text
MATRIZ

FILIAL
```

---

## Composite Types

Utilizados em Procedures.

Exemplo

```text
tp_endereco
```

Campos

- logradouro
- numero
- bairro
- cidade
- estado
- cep

---

Outro exemplo

```text
tp_contato
```

---

## Arrays

Utilizados em:

- permissões
- tags
- categorias
- anexos

---

## JSONB

Utilizado em:

- configurações
- integrações
- logs
- metadata
- auditoria
- parâmetros

---

### Auditoria

O Framework DBA verifica:

- Domains sem utilização
- ENUM não documentados
- Tipos órfãos
- Tipos duplicados
- Validações inconsistentes

---

### Boas Práticas

Todos os Domains deverão:

- possuir COMMENT ON DOMAIN
- utilizar nomenclatura padronizada
- possuir documentação
- ser reutilizados
- evitar duplicação
- possuir validações claras

---

### Dependências

Os Domains são utilizados por:

- Tables
- Views
- Procedures
- Functions
- Triggers
- APIs

---

### Estatísticas Previstas

| Categoria           |      Quantidade |
| ------------------- | --------------: |
| Domains Gerais      |              18 |
| Domains Financeiros |              20 |
| Domains Datas       |              12 |
| Domains Documentos  |              15 |
| Domains Contato     |              10 |
| Domains Auditoria   |              10 |
| ENUM Types          |              28 |
| Composite Types     |              12 |
| JSONB Estruturados  |              15 |
| **Total Estimado**  | **140 Objetos** |

---

### Critérios para Certificação

Todos os Domains deverão atender aos seguintes requisitos.

| Critério              | Obrigatório |
| --------------------- | :---------: |
| Nome padronizado      |     Sim     |
| COMMENT ON DOMAIN     |     Sim     |
| Documentação completa |     Sim     |
| Auditoria habilitada  |     Sim     |
| Reutilização adequada |     Sim     |

---

### Benefícios

A utilização de Domains e Tipos Personalizados proporciona:

- Padronização do modelo de dados
- Redução de redundância
- Centralização das regras de validação
- Facilidade de manutenção
- Melhor documentação
- Maior qualidade dos dados
- Integração com o Framework DBA
- Suporte ao processo de certificação do banco

---

## 6.20 Extensões PostgreSQL (Extensions)

As Extensões (Extensions) adicionam funcionalidades nativas ao PostgreSQL que não fazem parte do núcleo do banco de dados.

O WMA Travel ERP utiliza apenas extensões homologadas,
amplamente utilizadas pela comunidade PostgreSQL e compatíveis com ambientes corporativos.

---

### Objetivos

As Extensões possuem os seguintes objetivos:

- Expandir funcionalidades nativas
- Melhorar desempenho
- Aumentar segurança
- Suportar auditoria
- Facilitar buscas
- Otimizar consultas
- Simplificar desenvolvimento

---

## Política de Utilização

Todas as extensões deverão:

- ser homologadas
- possuir documentação oficial
- ser compatíveis com PostgreSQL LTS
- possuir controle de versão
- ser instaladas automaticamente pelos scripts do banco

---

### Estrutura da Documentação

Cada extensão documenta:

- Nome
- Objetivo
- Categoria
- Dependências
- Utilização
- Status

---

## Extensões Obrigatórias

## pgcrypto

Categoria

Segurança

Objetivo

Fornece funções criptográficas.

Principais recursos

- gen_random_uuid()
- digest()
- crypt()
- gen_salt()

Exemplo

```sql
SELECT gen_random_uuid();
```

Status

Obrigatória.

---

## uuid-ossp

Categoria

Identificadores

Objetivo

Geração de UUIDs.

Principais funções

- uuid_generate_v1()
- uuid_generate_v4()

Status

Opcional quando `pgcrypto` estiver disponível.

---

## unaccent

Categoria

Pesquisa

Objetivo

Remover acentuação durante pesquisas textuais.

Exemplo

```sql
SELECT unaccent('São Paulo');
```

Resultado

```text
Sao Paulo
```

---

## pg_trgm

Categoria

Pesquisa

Objetivo

Melhorar pesquisas aproximadas.

Aplicações

- Clientes
- Destinos
- Pacotes
- Hotéis
- Cidades

Operadores

```text
%

<->

similarity()
```

---

## btree_gin

Categoria

Índices

Objetivo

Permitir índices GIN para tipos B-Tree.

---

## btree_gist

Categoria

Índices

Objetivo

Permitir índices GiST adicionais.

---

## pg_stat_statements

Categoria

Performance

Objetivo

Monitoramento das consultas SQL.

Principais informações

- tempo médio
- quantidade de execuções
- consultas mais lentas
- consumo de CPU

Utilização

Framework DBA.

---

## tablefunc

Categoria

Relatórios

Objetivo

Disponibilizar funções para tabelas dinâmicas.

Principal função

```text
crosstab()
```

Aplicação

Business Intelligence.

---

## fuzzystrmatch

Categoria

Pesquisa

Objetivo

Comparação fonética.

Aplicações

- clientes
- cidades
- fornecedores

---

## hstore

Categoria

Estruturas

Objetivo

Armazenamento chave/valor.

Aplicação

Configurações simples.

---

## cube

Categoria

Matemática

Objetivo

Operações multidimensionais.

Uso

Business Intelligence.

---

## earthdistance

Categoria

Geolocalização

Objetivo

Calcular distância entre coordenadas.

Aplicações

- Turismo
- Bike Tour
- Hotéis
- Pontos turísticos

---

## postgres_fdw

Categoria

Integração

Objetivo

Acesso a bancos PostgreSQL remotos.

Aplicações

Integrações corporativas.

---

## Extensões Futuras

Planejadas para versões futuras.

## PostGIS

Objetivo

Geoprocessamento.

Aplicações

- mapas
- rotas
- cicloturismo
- georreferenciamento

---

## pgRouting

Objetivo

Rotas inteligentes.

Aplicações

Bike Tour.

---

## timescaledb

Objetivo

Séries temporais.

Aplicações

Monitoramento.

---

## Extensões Não Permitidas

Não serão utilizadas:

- extensões experimentais
- extensões sem manutenção
- extensões incompatíveis com PostgreSQL LTS

---

## Instalação

Exemplo

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

---

### Auditoria

O Framework DBA verifica automaticamente:

- extensões instaladas
- versões
- compatibilidade
- extensões ausentes
- extensões não utilizadas
- dependências

---

### Boas Práticas

Todas as extensões deverão:

- possuir justificativa técnica
- possuir documentação
- ser homologadas
- ser auditadas
- possuir controle de versão
- ser instaladas automaticamente

---

### Dependências

As extensões são utilizadas por:

- Tables
- Views
- Materialized Views
- Procedures
- Functions
- Triggers
- APIs
- Dashboard
- Framework DBA

---

### Estatísticas Previstas

| Categoria             |       Quantidade |
| --------------------- | ---------------: |
| Segurança             |                2 |
| Pesquisa              |                3 |
| Índices               |                2 |
| Performance           |                1 |
| Relatórios            |                1 |
| Geolocalização        |                2 |
| Integração            |                1 |
| Estruturas            |                1 |
| Business Intelligence |                2 |
| **Total Homologado**  | **15 Extensões** |

---

### Critérios para Certificação

Todas as extensões deverão atender aos seguintes requisitos.

| Critério                  | Obrigatório |
| ------------------------- | :---------: |
| Instalada                 |     Sim     |
| Homologada                |     Sim     |
| Documentada               |     Sim     |
| Compatível com PostgreSQL |     Sim     |
| Auditada                  |     Sim     |
| Versão Controlada         |     Sim     |

---

### Benefícios

A utilização controlada de extensões proporciona:

- Maior produtividade
- Melhor desempenho
- Recursos avançados
- Segurança
- Escalabilidade
- Facilidade de manutenção
- Integração corporativa
- Suporte ao Framework DBA
- Base para certificação técnica

---

## 6.21 Performance e Otimização

A camada de Performance e Otimização estabelece as diretrizes técnicas para garantir
que o banco de dados do WMA Travel ERP opere com alta disponibilidade,
baixa latência, escalabilidade e utilização eficiente dos recursos computacionais.

Esta política faz parte do Framework DBA e é continuamente monitorada pelo processo de Certificação Técnica do Banco.

---

### Objetivos

A estratégia de otimização possui os seguintes objetivos:

- Maximizar desempenho
- Reduzir tempo de resposta
- Minimizar consumo de recursos
- Otimizar consultas SQL
- Garantir escalabilidade
- Apoiar Business Intelligence
- Melhorar experiência do usuário
- Facilitar manutenção preventiva

---

## Áreas Monitoradas

O Framework DBA monitora continuamente:

- CPU
- Memória
- Disco
- I/O
- Locks
- Deadlocks
- Tempo de resposta
- Índices
- Estatísticas
- Sessões
- Conexões
- Replicação
- WAL
- Cache

---

## Estratégia de Otimização

A otimização é dividida em:

- Banco de Dados
- Consultas SQL
- Índices
- Estatísticas
- Armazenamento
- Memória
- Configuração
- Aplicação

---

## Estatísticas (ANALYZE)

As estatísticas deverão permanecer atualizadas.

Objetivos:

- melhorar planos de execução
- reduzir leituras desnecessárias
- otimizar JOINs
- otimizar filtros

Exemplo

```sql
ANALYZE;
```

Tabela específica

```sql
ANALYZE cliente;
```

---

## VACUUM

O VACUUM remove registros mortos (dead tuples).

Exemplo

```sql
VACUUM;
```

---

## VACUUM ANALYZE

```sql
VACUUM ANALYZE;
```

---

## VACUUM FULL

Utilizado apenas em manutenções programadas.

```sql
VACUUM FULL;
```

---

## REINDEX

Reconstrói índices fragmentados.

Exemplo

```sql
REINDEX DATABASE wmatravel;
```

---

Tabela específica

```sql
REINDEX TABLE cliente;
```

---

## CLUSTER

Reorganiza fisicamente uma tabela.

Utilização:

- tabelas muito consultadas
- tabelas históricas

---

## EXPLAIN

Toda consulta crítica deverá ser analisada.

```sql
EXPLAIN
SELECT *
FROM cliente;
```

---

## EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT *
FROM cliente;
```

Indicadores observados:

- Seq Scan
- Index Scan
- Bitmap Scan
- Nested Loop
- Hash Join
- Merge Join
- Tempo Total

---

### Índices

As seguintes situações são monitoradas:

- índices duplicados
- índices não utilizados
- índices inválidos
- índices ausentes
- índices fragmentados

---

## Consultas Lentas

Consultas com tempo superior a:

```text
500 ms
```

são classificadas como:

- Atenção

Consultas superiores a:

```text
2 segundos
```

são classificadas como:

- Críticas

---

### pg_stat_statements

Monitora:

- SQL mais executadas
- SQL mais lentas
- Tempo médio
- Tempo máximo
- Leituras
- Escritas

---

### Cache

Itens monitorados:

- Shared Buffers
- Cache Hit Ratio
- Buffer Reads
- Buffer Writes

Meta

```text
Cache Hit Ratio >= 99%
```

---

## Memória

Principais parâmetros:

```text
shared_buffers

work_mem

maintenance_work_mem

effective_cache_size

temp_buffers
```

---

## Configurações Recomendadas

## shared_buffers

```text
25% da memória RAM
```

---

## effective_cache_size

```text
75% da memória RAM
```

---

## work_mem

```text
16 MB
```

(valor ajustável conforme carga)

---

## maintenance_work_mem

```text
512 MB
```

---

## wal_buffers

```text
16 MB
```

---

## Paralelismo

Recursos utilizados:

- Parallel Seq Scan
- Parallel Hash
- Parallel Append
- Parallel Aggregate

---

## Particionamento

Utilizado para tabelas históricas.

Critérios:

- Data
- Ano
- Empresa
- Região

---

Exemplo

```text
fluxo_caixa

↓

2025

2026

2027
```

---

## Compressão

Utilizada em:

- Backups
- Arquivos históricos
- Logs

---

## Conexões

Monitoramento:

- Sessões ativas
- Sessões ociosas
- Tempo de conexão
- Sessões bloqueadas

---

## Locks

Monitoramento:

- Lock Wait
- Deadlock
- Long Transactions

---

## KPI de Performance

| Indicador                    | Meta     |
| ---------------------------- | -------- |
| Tempo médio das consultas    | < 100 ms |
| Cache Hit Ratio              | ≥ 99%    |
| Deadlocks                    | 0        |
| Seq Scan em tabelas críticas | Mínimo   |
| Índices utilizados           | ≥ 95%    |
| Consultas críticas           | < 2 s    |

---

### Auditoria

O Framework DBA verifica automaticamente:

- desempenho das consultas
- estatísticas desatualizadas
- necessidade de VACUUM
- necessidade de REINDEX
- índices ausentes
- índices duplicados
- consultas lentas
- bloqueios
- uso de memória
- utilização do cache

---

## Ferramentas Utilizadas

- pg_stat_statements
- EXPLAIN ANALYZE
- auto_explain
- pg_buffercache
- pg_stat_activity
- pg_locks
- pg_indexes
- pg_class

---

### Boas Práticas

Todas as consultas deverão:

- utilizar índices
- evitar SELECT *
- utilizar LIMIT quando aplicável
- evitar cursores desnecessários
- utilizar JOINs otimizados
- evitar funções em cláusulas WHERE quando possível
- possuir plano de execução analisado

---

## Integração com o Framework DBA

A camada de Performance fornece informações para:

- Health Check
- Índice de Conformidade do Banco (ICB)
- Dashboard Técnico
- Plano Automático de Correção
- Certificação Técnica

---

## Critérios para Certificação

| Critério                      | Obrigatório |
| ----------------------------- | :---------: |
| Estatísticas atualizadas      |     Sim     |
| VACUUM executado              |     Sim     |
| Índices íntegros              |     Sim     |
| Consultas críticas otimizadas |     Sim     |
| Cache adequado                |     Sim     |
| Sem deadlocks                 |     Sim     |
| Monitoramento ativo           |     Sim     |

---

## Benefícios

A estratégia de Performance proporciona:

- Alta disponibilidade
- Escalabilidade
- Menor consumo de recursos
- Melhor experiência do usuário
- Melhor desempenho das APIs
- Dashboards mais rápidos
- Base para Business Intelligence
- Suporte ao Framework DBA
- Certificação contínua do banco de dados

---

## 6.22 Backup, Recuperação e Continuidade de Negócios

A estratégia de Backup, Recuperação e Continuidade de Negócios do WMA Travel ERP
garante a proteção das informações corporativas contra falhas de hardware,
erros humanos, corrupção de dados, ataques cibernéticos e desastres operacionais.

Toda a política é monitorada automaticamente pelo Framework DBA
e faz parte do processo de Certificação Técnica do Banco de Dados.

---

### Objetivos

A política possui os seguintes objetivos:

- Garantir disponibilidade dos dados
- Minimizar perda de informações
- Garantir recuperação rápida
- Atender requisitos legais
- Proteger informações críticas
- Garantir continuidade operacional
- Apoiar auditorias
- Atender boas práticas corporativas

---

## Estratégia de Backup

A política de backup é composta por:

- Backup Completo (Full)
- Backup Incremental
- Backup Diferencial
- Arquivamento de WAL
- Backup Lógico
- Backup Físico
- Snapshot
- Replicação

---

## Tipos de Backup

### Backup Completo

Realizado semanalmente.

Características:

- Banco completo
- Estrutura
- Dados
- Objetos
- Permissões

---

### Backup Incremental

Realizado diariamente.

Inclui apenas alterações desde o último backup.

---

### Backup Diferencial

Realizado diariamente quando necessário.

Inclui alterações desde o último backup completo.

---

### Backup Lógico

Ferramenta utilizada:

```text
pg_dump
```

Exemplo:

```bash
pg_dump -Fc wmatravel > backup.dump
```

---

### Backup Físico

Ferramenta utilizada:

```text
pg_basebackup
```

Exemplo:

```bash
pg_basebackup -D backup/
```

---

## WAL Archiving

O arquivamento contínuo de WAL permite recuperação ponto no tempo.

Configuração:

```text
archive_mode = on

archive_command = ...
```

---

## Point-in-Time Recovery (PITR)

O PITR permite restaurar o banco exatamente em um instante específico.

Exemplo:

```text
31/12/2026

22:45:30
```

---

## Frequência

| Tipo             | Frequência |
| ---------------- | ---------- |
| Full             | Semanal    |
| Incremental      | Diário     |
| WAL              | Contínuo   |
| Snapshot         | Diário     |
| Teste de Restore | Mensal     |

---

## Retenção

| Backup  |   Retenção |
| ------- | ---------: |
| Diário  |    30 dias |
| Semanal | 12 semanas |
| Mensal  |   12 meses |
| Anual   | Permanente |

---

## Armazenamento

Os backups são armazenados em:

- Storage Local
- Storage Externo
- Nuvem
- Ambiente Offsite

---

## Criptografia

Todos os backups deverão utilizar criptografia.

Algoritmo recomendado:

```text
AES-256
```

---

## Compactação

Os backups deverão utilizar compactação.

Formatos recomendados:

- gzip
- zstd

---

## Validação

Após cada backup deverão ser verificados:

- integridade
- tamanho
- checksum
- consistência

---

## Testes de Recuperação

Os testes deverão ocorrer periodicamente.

Periodicidade:

| Teste             | Frequência |
| ----------------- | ---------- |
| Restore Parcial   | Mensal     |
| Restore Completo  | Trimestral |
| Disaster Recovery | Semestral  |

---

## Recovery Time Objective (RTO)

Tempo máximo aceitável para recuperação.

Meta:

```text
Até 2 horas
```

---

## Recovery Point Objective (RPO)

Perda máxima aceitável de dados.

Meta:

```text
Até 15 minutos
```

---

## Disaster Recovery (DR)

O plano contempla:

- perda total do servidor
- corrupção do banco
- falha de armazenamento
- ataque ransomware
- indisponibilidade do Data Center

---

## Alta Disponibilidade

Estratégias previstas:

- Replicação
- Standby
- Failover
- Hot Standby
- Streaming Replication

---

## Monitoramento

O Framework DBA monitora:

- último backup
- sucesso da execução
- tamanho
- crescimento
- integridade
- restauração
- validade

---

### Auditoria

São auditados:

- backups ausentes
- backups corrompidos
- falhas de execução
- retenção
- criptografia
- testes de restore

---

## Indicadores

| Indicador                | Meta |
| ------------------------ | ---- |
| Backup diário executado  | 100% |
| Backup semanal executado | 100% |
| Testes de Restore        | 100% |
| Backups íntegros         | 100% |
| Criptografia             | 100% |

---

### Boas Práticas

Todos os backups deverão:

- possuir criptografia
- possuir checksum
- possuir documentação
- possuir retenção
- possuir teste de restauração
- possuir monitoramento automático
- possuir auditoria

---

### Integração com o Framework DBA

O módulo de Backup fornece informações para:

- Dashboard Técnico
- Health Check
- Índice de Conformidade do Banco (ICB)
- Plano Automático de Correção
- Certificação Técnica

---

### Critérios para Certificação

| Critério             | Obrigatório |
| -------------------- | :---------: |
| Backup diário        |     Sim     |
| Backup completo      |     Sim     |
| WAL ativo            |     Sim     |
| PITR configurado     |     Sim     |
| Backup criptografado |     Sim     |
| Restore testado      |     Sim     |
| Retenção configurada |     Sim     |
| Auditoria ativa      |     Sim     |

---

### Benefícios

A política de Backup e Recuperação proporciona:

- Continuidade dos negócios
- Redução do risco operacional
- Recuperação rápida
- Segurança das informações
- Conformidade com boas práticas
- Maior confiabilidade
- Base para certificação técnica
- Suporte ao Framework DBA

--

## 6.23 Monitoramento e Observabilidade

O Monitoramento e a Observabilidade são responsáveis por acompanhar continuamente a saúde,
disponibilidade, desempenho e segurança do banco de dados PostgreSQL do WMA Travel ERP.

Esta camada integra o Framework DBA, permitindo detectar problemas de forma proativa,
reduzir indisponibilidades e fornecer informações para auditorias,
dashboards e certificação técnica.

---

### Objetivos

A política de monitoramento possui os seguintes objetivos:

- Garantir alta disponibilidade
- Detectar falhas antecipadamente
- Monitorar desempenho
- Monitorar utilização de recursos
- Identificar gargalos
- Apoiar auditorias
- Automatizar alertas
- Subsidiar decisões técnicas

---

## Escopo

O monitoramento contempla:

- Banco de Dados
- Sistema Operacional
- Servidor PostgreSQL
- Framework DBA
- API
- Aplicação
- Serviços Externos
- Infraestrutura

---

## Componentes Monitorados

## Banco de Dados

São monitorados continuamente:

- disponibilidade
- conexões
- sessões
- locks
- deadlocks
- consultas lentas
- índices
- cache
- WAL
- replicação

---

## Sistema Operacional

São monitorados:

- CPU
- memória
- disco
- utilização de swap
- rede
- processos

---

## Infraestrutura

Monitoramento de:

- armazenamento
- servidores
- backups
- firewall
- disponibilidade

---

## Métricas Coletadas

### Disponibilidade

Indicadores:

- uptime
- tempo de resposta
- disponibilidade geral

Meta:

```text
99,9%
```

---

### CPU

Indicadores:

- uso médio
- uso máximo
- carga

Alerta:

```text
> 80%
```

---

### Memória

Indicadores:

- memória utilizada
- memória livre
- cache
- swap

---

### Disco

Indicadores:

- espaço utilizado
- espaço livre
- crescimento
- IOPS

Alerta:

```text
> 85%
```

---

### Banco de Dados

Indicadores:

- conexões ativas
- conexões ociosas
- transações
- locks
- deadlocks
- checkpoints
- WAL
- autovacuum

---

## Monitoramento de Consultas

São monitoradas:

- consultas lentas
- consultas repetitivas
- consultas críticas
- consumo de recursos
- tempo médio
- tempo máximo

Ferramenta:

```text
pg_stat_statements
```

---

## Monitoramento de Locks

Itens monitorados:

- bloqueios
- espera por lock
- deadlocks
- transações longas

---

## Logs

São monitorados:

- erros
- warnings
- checkpoints
- autovacuum
- autenticação
- falhas
- recuperação

---

## Alertas Automáticos

O Framework DBA gera alertas para:

- backup não executado
- disco cheio
- consultas lentas
- deadlocks
- índices inválidos
- falha de replicação
- ausência de VACUUM
- corrupção detectada

---

## Ferramentas Homologadas

O ambiente poderá utilizar:

- pgAdmin
- Grafana
- Prometheus
- PostgreSQL Exporter
- Zabbix
- Nagios

---

## Dashboard Técnico

O Dashboard Técnico apresenta:

- saúde geral
- desempenho
- auditorias
- certificação
- backups
- indicadores
- alertas
- score técnico

---

## Health Check

O Health Check verifica automaticamente:

- disponibilidade
- integridade
- performance
- segurança
- backups
- índices
- estatísticas
- auditoria

---

## Indicadores (KPIs)

| Indicador                 | Meta     |
| ------------------------- | -------- |
| Disponibilidade           | ≥ 99,9%  |
| Tempo médio das consultas | < 100 ms |
| Deadlocks                 | 0        |
| Uso de CPU                | < 80%    |
| Uso de Disco              | < 85%    |
| Backup diário             | 100%     |
| Cache Hit Ratio           | ≥ 99%    |

---

## Eventos Monitorados

São registrados:

- inicialização
- desligamento
- falhas
- restore
- backup
- alterações estruturais
- migrações
- atualizações

---

### Auditoria

O Framework DBA audita:

- disponibilidade
- performance
- integridade
- segurança
- backups
- índices
- monitoramento
- observabilidade

---

### Boas Práticas

O monitoramento deverá:

- operar continuamente
- registrar histórico
- possuir alertas automáticos
- gerar indicadores
- manter dashboards atualizados
- permitir auditoria completa

---

### Integração com o Framework DBA

As informações alimentam:

- Dashboard Executivo
- Dashboard Técnico
- Health Check
- Índice de Conformidade do Banco (ICB)
- Plano Automático de Correção
- Certificação Técnica

---

### Critérios para Certificação

| Critério               | Obrigatório |
| ---------------------- | :---------: |
| Monitoramento contínuo |     Sim     |
| Alertas automáticos    |     Sim     |
| Histórico de métricas  |     Sim     |
| Dashboard atualizado   |     Sim     |
| Auditoria habilitada   |     Sim     |
| Health Check ativo     |     Sim     |

---

### Benefícios

O monitoramento contínuo proporciona:

- Alta disponibilidade
- Detecção proativa de problemas
- Redução de indisponibilidades
- Melhor desempenho
- Segurança operacional
- Histórico completo de eventos
- Base para auditorias
- Suporte ao Framework DBA
- Certificação contínua do banco de dados

---

## 6.24 Segurança do Banco de Dados

A Segurança do Banco de Dados define as políticas, mecanismos e controles utilizados
 para proteger as informações do WMA Travel ERP contra acessos não autorizados,
 perda de dados, vazamento de informações, alterações indevidas e ataques cibernéticos.

Esta camada integra o Framework DBA e faz parte do processo de Certificação Técnica do Banco de Dados.

---

### Objetivos

A política de segurança possui os seguintes objetivos:

- Garantir confidencialidade
- Garantir integridade
- Garantir disponibilidade
- Atender à LGPD
- Proteger informações críticas
- Controlar acessos
- Registrar auditorias
- Minimizar riscos operacionais

---

## Princípios

Toda a arquitetura de segurança segue os princípios:

- Menor Privilégio (Least Privilege)
- Defesa em Profundidade
- Segregação de Funções
- Auditoria Completa
- Segurança por Camadas
- Zero Trust
- Criptografia dos Dados
- Rastreabilidade

---

## Classificação das Informações

As informações do banco são classificadas em:

| Classificação | Descrição                  |
| ------------- | -------------------------- |
| Pública       | Informações sem restrição  |
| Interna       | Uso exclusivo da empresa   |
| Confidencial  | Dados estratégicos         |
| Restrita      | Dados protegidos pela LGPD |

---

## Controle de Acesso

Todo acesso ocorre através de:

- Usuários
- Roles
- Perfis
- Permissões
- Políticas de Segurança

---

## Roles Corporativas

As principais Roles do banco são:

| Role          | Finalidade             |
| ------------- | ---------------------- |
| dba_admin     | Administração completa |
| dba_auditoria | Auditoria              |
| app_backend   | API                    |
| app_frontend  | Aplicação              |
| bi_readonly   | Business Intelligence  |
| financeiro    | Financeiro             |
| comercial     | Comercial              |
| fiscal        | Fiscal                 |
| administrador | Administração ERP      |

---

## Política de Permissões

As permissões seguem o princípio do menor privilégio.

Permissões concedidas:

- SELECT
- INSERT
- UPDATE
- DELETE
- EXECUTE
- USAGE

Sempre concedidas explicitamente.

---

## Autenticação

Métodos suportados:

- Senha criptografada
- SCRAM-SHA-256
- Certificados
- LDAP (futuro)
- Active Directory (futuro)

---

### Criptografia

São utilizadas criptografias para:

- Senhas
- Backups
- Conexões
- Dados sensíveis

Algoritmos:

- AES-256
- SHA-256
- SCRAM-SHA-256
- TLS 1.3

---

## Conexões Seguras

Toda conexão deverá utilizar:

- SSL
- TLS
- Certificados válidos

Protocolos inseguros são proibidos.

---

## Dados Sensíveis

São considerados dados sensíveis:

- CPF
- CNPJ
- Passaporte
- RG
- Dados Bancários
- Telefones
- Endereços
- Informações Financeiras

---

## Mascaramento de Dados

Sempre que necessário serão aplicadas técnicas de:

- Masking
- Data Obfuscation
- Anonimização
- Pseudonimização

---

## LGPD

O banco atende aos princípios da Lei Geral de Proteção de Dados.

São implementados:

- Minimização de dados
- Finalidade
- Consentimento
- Retenção
- Exclusão
- Auditoria
- Rastreabilidade

---

## Row Level Security (RLS)

Sempre que necessário serão utilizadas políticas RLS.

Objetivos:

- Isolar empresas
- Isolar filiais
- Isolar usuários
- Garantir multitenancy

---

### Auditoria

Toda operação crítica gera auditoria.

Eventos registrados:

- Login
- Logout
- INSERT
- UPDATE
- DELETE
- ALTER
- CREATE
- DROP
- GRANT
- REVOKE

---

### Logs

São registrados:

- Usuário
- Data
- Hora
- IP
- Operação
- Objeto
- Resultado

---

## Políticas de Senha

As senhas deverão possuir:

- mínimo de 12 caracteres
- letras maiúsculas
- letras minúsculas
- números
- caracteres especiais

---

## Bloqueio de Conta

Após múltiplas tentativas inválidas:

- bloqueio automático
- registro em auditoria
- alerta ao administrador

---

## Backup Seguro

Todos os backups deverão:

- possuir criptografia
- possuir checksum
- possuir controle de acesso
- possuir retenção definida

---

### Monitoramento

São monitorados:

- acessos inválidos
- tentativas de invasão
- alterações de permissões
- elevação de privilégios
- consultas suspeitas
- uso excessivo de recursos

---

## Auditoria Automática

O Framework DBA verifica:

- usuários órfãos
- roles sem utilização
- privilégios excessivos
- objetos sem proprietário
- objetos públicos
- permissões inconsistentes

---

## Indicadores de Segurança

| Indicador            | Meta |
| -------------------- | ---- |
| Contas órfãs         | 0    |
| Objetos sem Owner    | 0    |
| Roles duplicadas     | 0    |
| Permissões públicas  | 0    |
| Auditoria ativa      | 100% |
| Backup criptografado | 100% |

---

## Ferramentas

A segurança utiliza:

- PostgreSQL Roles
- pgcrypto
- SSL/TLS
- SCRAM-SHA-256
- Framework DBA
- Auditoria Corporativa

---

### Integração com o Framework DBA

A camada de Segurança fornece informações para:

- Dashboard Técnico
- Dashboard Executivo
- Health Check
- Índice de Conformidade do Banco (ICB)
- Plano Automático de Correção
- Certificação Técnica

---

### Critérios para Certificação

| Critério             | Obrigatório |
| -------------------- | :---------: |
| Roles documentadas   |     Sim     |
| Permissões revisadas |     Sim     |
| Auditoria habilitada |     Sim     |
| Backup criptografado |     Sim     |
| SSL obrigatório      |     Sim     |
| LGPD atendida        |     Sim     |
| RLS quando aplicável |     Sim     |
| Framework DBA ativo  |     Sim     |

---

### Benefícios

A política de segurança proporciona:

- Proteção das informações corporativas
- Conformidade com a LGPD
- Redução dos riscos operacionais
- Controle de acessos
- Auditoria completa
- Rastreabilidade
- Maior confiabilidade
- Base para certificação técnica
- Integração total com o Framework DBA

---

## 6.25 Framework DBA e Certificação Técnica

O Framework DBA é o conjunto de processos, políticas, auditorias, métricas,
indicadores e ferramentas responsáveis pela administração, monitoramento,
governança e certificação técnica do banco de dados do WMA Travel ERP.

Este framework foi desenvolvido para garantir que o ambiente PostgreSQL permaneça seguro,
íntegro, documentado, performático e aderente às melhores práticas internacionais.

---

### Objetivos

O Framework DBA possui os seguintes objetivos:

- Padronizar a administração do banco
- Automatizar auditorias
- Garantir conformidade técnica
- Monitorar continuamente a saúde do banco
- Detectar inconsistências
- Gerar planos automáticos de correção
- Certificar tecnicamente o ambiente
- Apoiar a evolução contínua do ERP

---

## Componentes do Framework

O Framework DBA é composto pelos seguintes módulos:

- Auditoria Estrutural
- Auditoria Documental
- Auditoria de Performance
- Auditoria de Segurança
- Auditoria de Integridade
- Auditoria de Governança
- Health Check
- Índice de Conformidade do Banco (ICB)
- Plano Automático de Correção
- Certificação Técnica

---

## Arquitetura do Framework

```text
Framework DBA
│
├── Auditorias
│   ├── Estrutural
│   ├── Documental
│   ├── Performance
│   ├── Segurança
│   ├── Integridade
│   └── Governança
│
├── Health Check
│
├── Dashboard Técnico
│
├── Plano Automático de Correção
│
└── Certificação Técnica
```

---

## Auditorias Executadas

O Framework executa auditorias automáticas sobre:

- tabelas
- colunas
- índices
- constraints
- foreign keys
- sequences
- triggers
- procedures
- functions
- views
- materialized views
- comentários
- documentação
- permissões
- roles
- backups
- performance
- segurança

---

## Health Check

O Health Check avalia continuamente:

- disponibilidade
- desempenho
- integridade
- utilização de recursos
- segurança
- backups
- auditorias
- conformidade

---

### Índice de Conformidade do Banco (ICB)

O ICB representa o nível de conformidade técnica do banco de dados.

Faixa de classificação:

|    ICB | Classificação |
| -----: | ------------- |
| 95–100 | Excelente     |
|  90–94 | Muito Bom     |
|  80–89 | Bom           |
|  70–79 | Regular       |
|   < 70 | Crítico       |

---

## Critérios Avaliados

O cálculo do ICB considera:

- Estrutura
- Documentação
- Performance
- Segurança
- Integridade
- Governança
- Backup
- Monitoramento
- Auditoria

---

## Pesos

| Categoria     | Peso |
| ------------- | ---: |
| Estrutura     |  20% |
| Segurança     |  20% |
| Performance   |  15% |
| Integridade   |  15% |
| Governança    |  10% |
| Backup        |  10% |
| Monitoramento |   5% |
| Documentação  |   5% |

---

## Plano Automático de Correção

Sempre que uma auditoria detectar inconsistências, o Framework gera automaticamente um plano contendo:

- problema identificado
- impacto
- prioridade
- recomendação
- script sugerido
- responsável
- status

---

## Classificação das Não Conformidades

| Nível   | Descrição                                     |
| ------- | --------------------------------------------- |
| Baixa   | Não impacta operação                          |
| Média   | Impacto moderado                              |
| Alta    | Pode comprometer desempenho                   |
| Crítica | Pode comprometer disponibilidade ou segurança |

---

### Dashboard Técnico

O Dashboard apresenta:

- ICB
- Score Técnico
- Saúde Geral
- Auditorias
- Performance
- Segurança
- Backup
- Alertas
- Evolução histórica

---

## Dashboard Executivo

O Dashboard Executivo apresenta indicadores consolidados para gestão:

- disponibilidade
- conformidade
- risco operacional
- evolução da qualidade
- capacidade do ambiente
- tendências

---

### Indicadores (KPIs)

| Indicador                  | Meta   |
| -------------------------- | ------ |
| ICB                        | ≥ 95%  |
| Auditorias executadas      | 100%   |
| Não conformidades críticas | 0      |
| Backups válidos            | 100%   |
| Health Check               | Diário |
| Score Técnico              | ≥ 95%  |

---

## Frequência das Auditorias

| Auditoria    | Frequência |
| ------------ | ---------- |
| Estrutural   | Diária     |
| Performance  | Diária     |
| Segurança    | Diária     |
| Integridade  | Diária     |
| Backup       | Diária     |
| Documentação | Semanal    |
| Governança   | Mensal     |

---

## Certificação Técnica

A certificação somente poderá ser emitida quando:

- todas as auditorias forem concluídas;
- o ICB atingir no mínimo 95%;
- não existirem não conformidades críticas;
- backup e restore estiverem validados;
- documentação estiver completa;
- políticas de segurança estiverem ativas.

---

## Níveis de Maturidade

| Nível   | Descrição    |
| ------- | ------------ |
| Nível 1 | Básico       |
| Nível 2 | Padronizado  |
| Nível 3 | Gerenciado   |
| Nível 4 | Automatizado |
| Nível 5 | Certificado  |

Objetivo do WMA Travel ERP:

```text
Nível 5 — Certificado
```

---

## Integração

O Framework DBA integra-se aos seguintes componentes:

- PostgreSQL
- API REST
- Dashboard Executivo
- Dashboard Técnico
- Business Intelligence
- Sistema de Logs
- Monitoramento
- Auditoria Corporativa

---

## Benefícios

A utilização do Framework DBA proporciona:

- padronização técnica;
- redução de riscos;
- maior disponibilidade;
- melhoria contínua;
- automação de auditorias;
- suporte à tomada de decisão;
- rastreabilidade completa;
- conformidade corporativa;
- certificação técnica do banco de dados.

---

## Critérios para Certificação Final

| Critério              | Obrigatório |
| --------------------- | :---------: |
| ICB ≥ 95%             |     Sim     |
| Framework DBA ativo   |     Sim     |
| Auditorias concluídas |     Sim     |
| Health Check aprovado |     Sim     |
| Backups válidos       |     Sim     |
| Segurança validada    |     Sim     |
| Documentação completa |     Sim     |
| Dashboard atualizado  |     Sim     |

---

## 6.26 Glossário Técnico

Este glossário reúne os principais termos técnicos utilizados na documentação do WMA Travel ERP,
proporcionando uma referência única para desenvolvedores, DBAs, analistas, arquitetos de software e auditores.

---

### Objetivos

O Glossário possui os seguintes objetivos:

- Padronizar a terminologia técnica
- Facilitar a compreensão da documentação
- Evitar ambiguidades
- Apoiar treinamentos
- Servir como referência para novos colaboradores
- Apoiar auditorias e governança

---

## Termos Gerais

## API

Application Programming Interface.

Conjunto de serviços utilizados para comunicação entre sistemas.

---

### Banco de Dados

Repositório estruturado responsável pelo armazenamento das informações do ERP.

---

## PostgreSQL

Sistema Gerenciador de Banco de Dados Relacional (SGBDR) utilizado pelo WMA Travel ERP.

---

## Schema

Agrupamento lógico de objetos do banco de dados.

---

## Tabela

Estrutura responsável pelo armazenamento dos dados.

---

## Coluna

Campo pertencente a uma tabela.

---

## Registro

Linha armazenada em uma tabela.

---

## Objetos do Banco

### Primary Key (PK)

Chave Primária.

Identifica unicamente um registro.

---

### Foreign Key (FK)

Chave Estrangeira.

Relaciona duas tabelas.

---

### Constraint

Regra utilizada para garantir integridade dos dados.

---

### Sequence

Objeto responsável pela geração automática de identificadores.

---

### Trigger

Procedimento executado automaticamente após determinado evento.

---

### Function

Objeto que retorna um valor após execução.

---

### Procedure

Objeto responsável por executar rotinas sem necessidade de retorno.

---

### View

Consulta armazenada utilizada como tabela virtual.

---

### Materialized View

Consulta persistida fisicamente.

---

### Index

Estrutura utilizada para acelerar consultas.

---

## Segurança

### Role

Conjunto de permissões atribuídas a usuários.

---

### Permission

Autorização concedida para execução de determinada operação.

---

## RLS

Row Level Security.

Controle de acesso por registro.

---

### LGPD

Lei Geral de Proteção de Dados.

Legislação brasileira responsável pela proteção dos dados pessoais.

---

### Criptografia

Processo de proteção das informações através de algoritmos matemáticos.

---

### TLS

Transport Layer Security.

Protocolo utilizado para comunicação segura.

---

## Performance

### VACUUM

Processo responsável pela limpeza de registros mortos.

---

### ANALYZE

Atualização das estatísticas utilizadas pelo otimizador do PostgreSQL.

---

### EXPLAIN

Comando utilizado para visualizar o plano de execução de uma consulta.

---

### EXPLAIN ANALYZE

Executa a consulta e apresenta o plano real de execução.

---

### Cache Hit Ratio

Percentual de consultas atendidas diretamente pela memória.

---

### Deadlock

Situação onde duas ou mais transações aguardam recursos mutuamente.

---

## Backup

### Backup Full

Cópia completa do banco de dados.

---

### Backup Incremental

Cópia apenas das alterações desde o último backup.

---

### PITR

Point-in-Time Recovery.

Recuperação do banco para um instante específico.

---

### WAL

Write Ahead Log.

Arquivo de transações utilizado para recuperação do banco.

---

### Restore

Processo de restauração de um backup.

---

## Framework DBA

### Health Check

Rotina automatizada responsável pela verificação da saúde do banco.

---

### ICB

Índice de Conformidade do Banco.

Indicador que mede o nível de aderência às boas práticas estabelecidas.

---

### Score Técnico

Pontuação consolidada utilizada pelo processo de certificação.

---

### Plano Automático de Correção

Documento gerado automaticamente contendo recomendações para correção de inconsistências.

---

### Certificação Técnica

Processo que valida a conformidade estrutural, documental, operacional e de segurança do banco de dados.

---

## Desenvolvimento

## Clean Code

Conjunto de boas práticas para desenvolvimento de código legível e sustentável.

---

## SOLID

Princípios de orientação a objetos voltados para software de alta qualidade.

---

## DDD

Domain Driven Design.

Metodologia de desenvolvimento orientada ao domínio do negócio.

---

## SemVer

Semantic Versioning.

Padrão de versionamento utilizado pelo projeto.

Formato:

```text
MAJOR.MINOR.PATCH
```

---

## Git

Sistema distribuído de controle de versões.

---

## GitHub

Plataforma utilizada para hospedagem e gerenciamento do código-fonte.

---

## Business Intelligence

## Dashboard

Painel de indicadores utilizado para acompanhamento gerencial e operacional.

---

## KPI

Key Performance Indicator.

Indicador-chave de desempenho.

---

## ETL

Extract, Transform and Load.

Processo de extração, transformação e carga de dados.

---

## Turismo

### Pacote Turístico

Conjunto de serviços comercializados de forma integrada.

---

### Reserva

Registro de contratação de serviços turísticos.

---

## Bike Tour

Modalidade de turismo baseada em cicloturismo e experiências ao ar livre.

---

### Convenções

Todos os termos técnicos utilizados no projeto deverão seguir as definições estabelecidas neste glossário.

Novos termos deverão ser incluídos neste capítulo sempre que forem incorporados ao projeto.

---

### Benefícios

A utilização deste glossário proporciona:

- Padronização terminológica
- Facilidade de comunicação
- Melhor entendimento da documentação
- Apoio ao treinamento de equipes
- Redução de ambiguidades
- Maior qualidade documental

---

## 6.27 Referências Técnicas

Este capítulo reúne as principais referências técnicas, normas, padrões,
documentações oficiais e boas práticas utilizadas durante a concepção, desenvolvimento e manutenção do WMA Travel ERP.

Todas as tecnologias empregadas no projeto possuem documentação oficial amplamente reconhecida pela comunidade técnica.

---

### Objetivos

Este capítulo possui os seguintes objetivos:

- Padronizar as referências utilizadas
- Facilitar consultas técnicas
- Apoiar auditorias
- Auxiliar treinamentos
- Garantir rastreabilidade
- Documentar normas adotadas

---

### Banco de Dados

### PostgreSQL

Documentação oficial utilizada durante todo o desenvolvimento.

Principais assuntos consultados:

- SQL
- PL/pgSQL
- Índices
- Triggers
- Functions
- Procedures
- Views
- Materialized Views
- Performance
- Replicação
- Backup
- Segurança

Referência

```text
PostgreSQL Official Documentation
https://www.postgresql.org/docs/
```

---

## SQL

## ISO/IEC 9075

Padrão internacional da linguagem SQL.

Aplicação:

- Modelagem
- Consultas
- Integridade
- Constraints

---

### Segurança

## ISO/IEC 27001

Norma internacional para Sistemas de Gestão da Segurança da Informação.

Aplicações:

- Segurança
- Auditoria
- Governança
- Gestão de riscos

---

## ISO/IEC 27002

Boas práticas para controles de segurança da informação.

---

## OWASP

Open Worldwide Application Security Project.

Aplicações:

- Segurança de APIs
- Segurança Web
- Controle de vulnerabilidades

Referência

```text
https://owasp.org
```

---

## CIS PostgreSQL Benchmark

Guia internacional de hardening para PostgreSQL.

Aplicações:

- Segurança
- Configuração
- Auditoria
- Compliance

---

## Governança

## COBIT

Framework para Governança de Tecnologia da Informação.

Aplicações:

- Gestão
- Auditoria
- Processos

---

## ITIL

Boas práticas para Gestão de Serviços de TI.

Aplicações:

- Operação
- Incidentes
- Mudanças
- Continuidade

---

### Desenvolvimento

## Clean Architecture

Arquitetura proposta por Robert C. Martin.

Aplicações:

- Organização do código
- Independência de camadas
- Escalabilidade

---

### Clean Code

Conjunto de boas práticas para desenvolvimento de software.

Autor

```text
Robert C. Martin
```

---

### SOLID

Princípios de orientação a objetos.

Aplicações:

- Backend
- APIs
- Serviços

---

## Domain Driven Design (DDD)

Modelagem baseada no domínio do negócio.

Aplicações:

- ERP
- Turismo
- Financeiro

---

## Versionamento

## Semantic Versioning

Padrão utilizado pelo projeto.

Formato

```text
MAJOR.MINOR.PATCH
```

Referência

```text
https://semver.org
```

---

## Keep a Changelog

Padrão utilizado para documentação das versões.

Referência

```text
https://keepachangelog.com
```

---

### Git

Documentação oficial do Git.

Aplicações:

- Controle de versão
- Branches
- Merge
- Tags

Referência

```text
https://git-scm.com
```

---

### GitHub

Aplicações:

- Repositório
- Pull Requests
- Issues
- Releases

Referência

```text
https://docs.github.com
```

---

### Python

Documentação oficial da linguagem.

Aplicações:

- Backend
- Scripts
- Framework DBA

Referência

```text
https://docs.python.org
```

---

### PEP

Python Enhancement Proposals.

Aplicações:

- Convenções
- Estilo
- Tipagem

---

### FastAPI

Framework utilizado na API do ERP.

Aplicações:

- REST API
- OpenAPI
- Swagger

Referência

```text
https://fastapi.tiangolo.com
```

---

### SQLAlchemy

ORM oficial do projeto.

Aplicações:

- Persistência
- Mapeamento
- Migrações

Referência

```text
https://sqlalchemy.org
```

---

### Alembic

Ferramenta para migração de banco de dados.

Aplicações:

- Versionamento
- Deploy

---

### React

Biblioteca utilizada no Front-end.

Referência

```text
https://react.dev
```

---

### TypeScript

Linguagem utilizada no Front-end.

Referência

```text
https://www.typescriptlang.org
```

---

### Flutter

Framework Mobile.

Aplicações:

- Android
- iOS

Referência

```text
https://flutter.dev
```

---

### Microsoft Power BI

Ferramenta de Business Intelligence.

Aplicações:

- Dashboards
- Indicadores
- Relatórios

Referência

```text
https://powerbi.microsoft.com
```

---

### LGPD

Lei nº 13.709/2018.

Aplicações:

- Proteção de Dados
- Privacidade
- Consentimento
- Auditoria

---

### Convenções Utilizadas

O projeto adota os seguintes padrões:

- PostgreSQL Style Guide
- SQL Standard
- Git Flow
- Semantic Versioning
- Keep a Changelog
- Markdownlint
- Conventional Commits

---

### Compatibilidade

O projeto é compatível com:

| Tecnologia | Versão    |
| ---------- | --------- |
| PostgreSQL | 15+       |
| Python     | 3.12+     |
| FastAPI    | Atual LTS |
| SQLAlchemy | 2.x       |
| React      | Atual LTS |
| Flutter    | Atual LTS |

---

### Atualização das Referências

Todas as referências deverão ser revisadas periodicamente.

Periodicidade recomendada:

| Item       | Frequência                |
| ---------- | ------------------------- |
| PostgreSQL | Anual                     |
| Python     | Anual                     |
| Frameworks | Semestral                 |
| Normas ISO | Quando houver atualização |
| LGPD       | Conforme legislação       |

---

### Benefícios

A utilização destas referências proporciona:

- Padronização técnica
- Confiabilidade
- Rastreabilidade
- Conformidade com normas internacionais
- Facilidade de manutenção
- Evolução contínua do projeto

---

## Apêndice A — Convenções de Nomenclatura

Este apêndice estabelece as convenções oficiais de nomenclatura adotadas no WMA Travel
ERP para bancos de dados, objetos PostgreSQL, APIs, documentação e código-fonte.

A padronização garante consistência, legibilidade, facilidade de manutenção e integração entre todos os módulos do sistema.

---

### Objetivos

As convenções possuem os seguintes objetivos:

- Padronizar nomenclaturas
- Facilitar manutenção
- Melhorar legibilidade
- Evitar ambiguidades
- Apoiar auditorias
- Garantir consistência entre módulos

---

## Regras Gerais

Todos os objetos deverão obedecer às seguintes regras:

- utilizar letras minúsculas;
- utilizar snake_case;
- não utilizar espaços;
- não utilizar acentos;
- não utilizar caracteres especiais;
- utilizar nomes descritivos;
- evitar abreviações sem padronização.

---

## Banco de Dados

### Nome do Banco

Formato

```text
wmatravel
```

---

### Schemas

Formato

```text
public

financeiro

fiscal

turismo

administrativo

auditoria

configuracao
```

---

### Tabelas

Formato

```text
cliente

empresa

conta_bancaria

fluxo_caixa

pacote_turistico
```

Regra

```text
snake_case

singular
```

---

### Colunas

Formato

```text
id_cliente

nome

data_cadastro

valor_total

ativo
```

---

### Chaves Primárias

Formato

```text
id_<tabela>
```

Exemplos

```text
id_cliente

id_empresa

id_usuario

id_fluxo_caixa
```

---

### Chaves Estrangeiras

Formato

```text
id_<tabela_referenciada>
```

Exemplos

```text
id_empresa

id_cliente

id_usuario
```

---

### Constraints

### Primary Key

Formato

```text
pk_<tabela>
```

Exemplo

```text
pk_cliente
```

---

### Foreign Key

Formato

```text
fk_<tabela>_<referencia>
```

Exemplos

```text
fk_cliente_empresa

fk_fluxo_caixa_categoria

fk_usuario_perfil
```

---

### Unique

Formato

```text
uk_<tabela>_<campo>
```

Exemplo

```text
uk_cliente_cpf
```

---

### Check

Formato

```text
ck_<tabela>_<campo>
```

Exemplo

```text
ck_fluxo_valor
```

---

### Índices

Formato

```text
idx_<tabela>_<campo>
```

Exemplos

```text
idx_cliente_nome

idx_empresa_cnpj

idx_fluxo_data
```

---

## Sequences

Formato

```text
seq_<tabela>
```

Exemplo

```text
seq_cliente
```

---

## Views

Formato

```text
vw_<nome>
```

Exemplos

```text
vw_dre

vw_fluxo_caixa

vw_dashboard
```

---

## Materialized Views

Formato

```text
mv_<nome>
```

Exemplo

```text
mv_indicadores
```

---

## Procedures

Formato

```text
sp_<nome>
```

Exemplos

```text
sp_fechamento_mensal

sp_recalcular_saldos
```

---

## Functions

Formato

```text
fn_<nome>
```

Exemplos

```text
fn_calcular_saldo

fn_validar_cpf
```

---

## Triggers

Formato

```text
trg_<tabela>_<evento>
```

Exemplos

```text
trg_cliente_insert

trg_empresa_update
```

---

## Tipos Personalizados

Formato

```text
tp_<nome>
```

---

## Domains

Formato

```text
dm_<nome>
```

---

## APIs

Formato

```text
/api/v1/clientes

/api/v1/empresas

/api/v1/financeiro
```

---

## Classes Python

Formato

```text
PascalCase
```

Exemplos

```text
ClienteService

FluxoCaixaRepository

EmpresaController
```

---

## Métodos Python

Formato

```text
snake_case
```

Exemplos

```text
calcular_saldo()

buscar_cliente()

gerar_relatorio()
```

---

## Variáveis Python

Formato

```text
snake_case
```

---

## Constantes

Formato

```text
MAIÚSCULAS_COM_UNDERSCORE
```

Exemplos

```text
MAX_TENTATIVAS

TIMEOUT_API

VERSAO_SISTEMA
```

---

## Arquivos SQL

Formato

```text
NN_NN_nome.sql
```

Exemplos

```text
04_00_core.sql

04_01_auditoria.sql

22_00_framework_dba.sql
```

---

## Arquivos Markdown

Formato

```text
MAIÚSCULAS.md
```

Exemplos

```text
README.md

CHANGELOG.md

ROADMAP.md

DATABASE_GUIDE.md
```

---

## Branches Git

Formato

```text
feature/

fix/

release/

hotfix/
```

Exemplos

```text
feature/framework-dba

feature/financeiro

fix/indexes

release/v1.0.0
```

---

## Commits

Padrão

```text
feat:

fix:

docs:

refactor:

test:

style:

perf:

build:

ci:
```

---

### Versionamento

Formato

```text
MAJOR.MINOR.PATCH
```

Exemplo

```text
1.0.0
```

---

### Benefícios

A adoção destas convenções proporciona:

- Padronização completa
- Facilidade de manutenção
- Melhor legibilidade
- Redução de erros
- Integração entre equipes
- Maior qualidade do código
- Conformidade com o Framework DBA

---

## Apêndice B — Checklist de Conformidade

Este checklist estabelece os critérios oficiais utilizados pelo Framework DBA
para avaliar a conformidade técnica do banco de dados do WMA Travel ERP.

Cada item é verificado automaticamente durante as auditorias e
contribui para o cálculo do Índice de Conformidade do Banco (ICB) e da Certificação Técnica.

---

### Objetivos

O checklist possui os seguintes objetivos:

- Padronizar auditorias
- Validar conformidade técnica
- Identificar não conformidades
- Apoiar homologações
- Automatizar verificações
- Garantir melhoria contínua

---

## Estrutura do Checklist

Cada item deverá possuir um dos seguintes status:

| Status        | Descrição                         |
| ------------- | --------------------------------- |
| Conforme      | Atende integralmente ao requisito |
| Parcial       | Atende parcialmente               |
| Não Conforme  | Não atende ao requisito           |
| Não Aplicável | Requisito não se aplica           |

---

## 1. Estrutura do Banco

| Item                 | Obrigatório |
| -------------------- | :---------: |
| Banco criado         |     Sim     |
| Encoding UTF-8       |     Sim     |
| Locale configurado   |     Sim     |
| Timezone configurado |     Sim     |
| Schemas padronizados |     Sim     |
| Owner definido       |     Sim     |

---

## 2. Tabelas

| Item                          | Obrigatório |
| ----------------------------- | :---------: |
| Todas as tabelas documentadas |     Sim     |
| Nome padronizado              |     Sim     |
| Comentários preenchidos       |     Sim     |
| Chave primária existente      |     Sim     |
| Auditoria habilitada          |     Sim     |

---

## 3. Colunas

| Item                           | Obrigatório |
| ------------------------------ | :---------: |
| Nome padronizado               |     Sim     |
| Tipo correto                   |     Sim     |
| Comentário preenchido          |     Sim     |
| NULL corretamente definido     |     Sim     |
| Valor padrão quando necessário |     Sim     |

---

## 4. Chaves Primárias

| Item             | Obrigatório |
| ---------------- | :---------: |
| PK existente     |     Sim     |
| Nome padronizado |     Sim     |
| Índice criado    |     Sim     |

---

## 5. Chaves Estrangeiras

| Item                 | Obrigatório |
| -------------------- | :---------: |
| FK existente         |     Sim     |
| Nome padronizado     |     Sim     |
| Integridade validada |     Sim     |
| Índice criado        |     Sim     |

---

## 6. Índices

| Item                            | Obrigatório |
| ------------------------------- | :---------: |
| Índices duplicados inexistentes |     Sim     |
| Índices inválidos inexistentes  |     Sim     |
| Índices documentados            |     Sim     |
| Índices utilizados              |     Sim     |

---

## 7. Constraints

| Item                     | Obrigatório |
| ------------------------ | :---------: |
| CHECK documentadas       |     Sim     |
| UNIQUE documentadas      |     Sim     |
| FOREIGN KEY documentadas |     Sim     |
| PRIMARY KEY documentadas |     Sim     |

---

## 8. Sequences

| Item                   | Obrigatório |
| ---------------------- | :---------: |
| Sequence existente     |     Sim     |
| Vinculada corretamente |     Sim     |
| Nome padronizado       |     Sim     |

---

## 9. Views

| Item                 | Obrigatório |
| -------------------- | :---------: |
| Documentadas         |     Sim     |
| Comentadas           |     Sim     |
| Performance validada |     Sim     |

---

## 10. Materialized Views

| Item                    | Obrigatório |
| ----------------------- | :---------: |
| Atualização definida    |     Sim     |
| Índices criados         |     Sim     |
| Comentários preenchidos |     Sim     |

---

## 11. Procedures

| Item                   | Obrigatório |
| ---------------------- | :---------: |
| Nome padronizado       |     Sim     |
| Comentários            |     Sim     |
| Tratamento de exceções |     Sim     |

---

## 12. Functions

| Item                | Obrigatório |
| ------------------- | :---------: |
| Nome padronizado    |     Sim     |
| Comentários         |     Sim     |
| Retorno documentado |     Sim     |

---

## 13. Triggers

| Item               | Obrigatório |
| ------------------ | :---------: |
| Nome padronizado   |     Sim     |
| Evento documentado |     Sim     |
| Auditoria validada |     Sim     |

---

## 14. Segurança

| Item                 | Obrigatório |
| -------------------- | :---------: |
| Roles configuradas   |     Sim     |
| Permissões revisadas |     Sim     |
| SSL habilitado       |     Sim     |
| Backup criptografado |     Sim     |
| Auditoria ativa      |     Sim     |

---

## 15. Performance

| Item                          | Obrigatório |
| ----------------------------- | :---------: |
| Estatísticas atualizadas      |     Sim     |
| VACUUM executado              |     Sim     |
| Índices utilizados            |     Sim     |
| Consultas críticas otimizadas |     Sim     |

---

## 16. Backup

| Item                 | Obrigatório |
| -------------------- | :---------: |
| Backup diário        |     Sim     |
| Backup completo      |     Sim     |
| Teste de restore     |     Sim     |
| Retenção configurada |     Sim     |

---

## 17. Monitoramento

| Item                 | Obrigatório |
| -------------------- | :---------: |
| Health Check ativo   |     Sim     |
| Alertas configurados |     Sim     |
| Logs monitorados     |     Sim     |
| Dashboard atualizado |     Sim     |

---

## 18. Documentação

| Item                       | Obrigatório |
| -------------------------- | :---------: |
| Data Dictionary atualizado |     Sim     |
| Architecture atualizado    |     Sim     |
| README atualizado          |     Sim     |
| Changelog atualizado       |     Sim     |
| Roadmap atualizado         |     Sim     |

---

## 19. Governança

| Item                         | Obrigatório |
| ---------------------------- | :---------: |
| Versionamento ativo          |     Sim     |
| Framework DBA atualizado     |     Sim     |
| Auditorias executadas        |     Sim     |
| Plano de Correção atualizado |     Sim     |

---

## 20. Certificação Técnica

Para emissão da Certificação Técnica deverão ser atendidos os seguintes critérios mínimos:

| Critério                     | Valor |
| ---------------------------- | ----: |
| Índice de Conformidade (ICB) | ≥ 95% |
| Não conformidades críticas   |     0 |
| Auditorias concluídas        |  100% |
| Backup validado              |   Sim |
| Segurança validada           |   Sim |
| Performance aprovada         |   Sim |
| Documentação completa        |   Sim |

---

## Resultado Final

| Faixa         | Situação                   |
| ------------- | -------------------------- |
| 95–100%       | Banco Certificado          |
| 90–94%        | Aprovado com Recomendações |
| 80–89%        | Necessita Correções        |
| Abaixo de 80% | Reprovado                  |

---

### Benefícios

A utilização deste checklist proporciona:

- Homologação padronizada
- Auditorias repetíveis
- Maior confiabilidade
- Rastreabilidade das verificações
- Melhoria contínua
- Base para Certificação Técnica do Banco
- Integração completa com o Framework DBA

---

## Apêndice C — Estatísticas Consolidadas do Banco de Dados

Este apêndice apresenta o inventário consolidado da estrutura do banco de dados do WMA Travel ERP.

As informações são utilizadas pelo Framework DBA para monitoramento,
auditoria, planejamento de capacidade e certificação técnica.

---

### Objetivos

Este apêndice possui os seguintes objetivos:

- Inventariar todos os objetos do banco
- Apoiar auditorias
- Auxiliar planejamento de capacidade
- Medir evolução estrutural
- Fornecer indicadores técnicos
- Servir como referência para certificação

---

### Visão Geral

O banco de dados do WMA Travel ERP foi projetado utilizando arquitetura corporativa modular.

As estatísticas apresentadas neste documento deverão ser atualizadas automaticamente durante o processo de auditoria.

---

## Estrutura Geral

| Item               |             Quantidade |
| ------------------ | ---------------------: |
| Bancos de Dados    |                      1 |
| Schemas            | Conforme implementação |
| Tabelas            | Conforme implementação |
| Views              | Conforme implementação |
| Materialized Views | Conforme implementação |
| Functions          | Conforme implementação |
| Procedures         | Conforme implementação |
| Triggers           | Conforme implementação |
| Sequences          | Conforme implementação |
| Domains            | Conforme implementação |
| Índices            | Conforme implementação |
| Constraints        | Conforme implementação |

---

## Estatísticas das Tabelas

Serão monitorados:

- quantidade total
- tabelas por schema
- tabelas por módulo
- crescimento mensal
- tabelas documentadas
- tabelas auditadas

---

### Exemplo

| Módulo         | Tabelas |
| -------------- | ------: |
| Administrativo |       — |
| Financeiro     |       — |
| Fiscal         |       — |
| Comercial      |       — |
| Turismo        |       — |
| Bike Tour      |       — |
| Configuração   |       — |
| Auditoria      |       — |

---

## Estatísticas de Colunas

Indicadores monitorados:

- quantidade total
- colunas documentadas
- colunas obrigatórias
- colunas opcionais
- colunas auditadas

---

## Estatísticas de Índices

Itens monitorados:

- índices totais
- índices utilizados
- índices duplicados
- índices inválidos
- índices não utilizados

---

### Indicadores

| Indicador          |              Valor |
| ------------------ | -----------------: |
| Índices utilizados | Conforme auditoria |
| Índices duplicados | Conforme auditoria |
| Índices inválidos  | Conforme auditoria |

---

## Estatísticas de Constraints

São monitoradas:

- PRIMARY KEY
- FOREIGN KEY
- UNIQUE
- CHECK
- EXCLUDE

---

### Exemplo

| Constraint  | Quantidade |
| ----------- | ---------: |
| Primary Key |          — |
| Foreign Key |          — |
| Unique      |          — |
| Check       |          — |

---

## Estatísticas de Relacionamentos

São contabilizados:

- relacionamentos 1:1
- relacionamentos 1:N
- relacionamentos N:N
- relacionamentos opcionais
- relacionamentos obrigatórios

---

## Estatísticas de Views

Itens monitorados:

- Views
- Materialized Views
- Views documentadas
- Views utilizadas

---

## Estatísticas de Procedures

São monitoradas:

- quantidade
- documentadas
- auditadas
- utilizadas

---

## Estatísticas de Functions

São monitoradas:

- quantidade
- documentadas
- utilizadas
- desempenho

---

## Estatísticas de Triggers

São monitoradas:

- BEFORE
- AFTER
- INSERT
- UPDATE
- DELETE
- EVENT

---

## Estatísticas de Auditoria

Itens monitorados:

- auditorias executadas
- auditorias aprovadas
- auditorias pendentes
- não conformidades

---

## Estatísticas de Segurança

São contabilizados:

- usuários
- roles
- permissões
- objetos protegidos
- objetos auditados

---

## Estatísticas de Backup

Indicadores:

- backups realizados
- backups válidos
- restores testados
- PITR disponível

---

## Estatísticas de Performance

Itens monitorados:

- tempo médio de consulta
- consultas lentas
- cache hit ratio
- utilização de CPU
- utilização de memória
- utilização de disco

---

## Estatísticas de Crescimento

São registrados:

- crescimento diário
- crescimento mensal
- crescimento anual
- projeção futura

---

### Indicadores Técnicos

| Indicador             | Meta    |
| --------------------- | ------- |
| Disponibilidade       | ≥ 99,9% |
| Cache Hit Ratio       | ≥ 99%   |
| Consultas lentas      | 0       |
| Deadlocks             | 0       |
| Backup válido         | 100%    |
| Auditorias executadas | 100%    |

---

### Índice de Conformidade do Banco (ICB)

O Framework DBA consolida automaticamente o ICB.

Faixas:

| Faixa  | Classificação |
| ------ | ------------- |
| 95–100 | Excelente     |
| 90–94  | Muito Bom     |
| 80–89  | Bom           |
| 70–79  | Regular       |
| < 70   | Crítico       |

---

## Score Técnico

O Score Técnico é composto pelos seguintes componentes:

| Categoria     | Peso |
| ------------- | ---: |
| Estrutura     |  20% |
| Segurança     |  20% |
| Performance   |  15% |
| Integridade   |  15% |
| Backup        |  10% |
| Governança    |  10% |
| Monitoramento |   5% |
| Documentação  |   5% |

---

## Atualização das Estatísticas

As estatísticas deverão ser atualizadas automaticamente:

| Processo                 | Frequência  |
| ------------------------ | ----------- |
| Auditoria Estrutural     | Diária      |
| Auditoria de Segurança   | Diária      |
| Auditoria de Performance | Diária      |
| Backup                   | Diária      |
| Dashboard Técnico        | Tempo real  |
| Certificação             | Sob demanda |

---

## Fontes das Informações

As estatísticas são obtidas a partir de:

- Catálogo do PostgreSQL
- Views do sistema
- Framework DBA
- Auditorias automáticas
- Health Check
- Dashboard Técnico

---

### Benefícios

A consolidação estatística proporciona:

- Inventário completo do banco
- Planejamento de capacidade
- Acompanhamento da evolução
- Base para auditorias
- Apoio à certificação técnica
- Monitoramento contínuo
- Indicadores estratégicos
- Governança de dados

---

## Apêndice D — Matriz de Rastreabilidade

A Matriz de Rastreabilidade estabelece o relacionamento entre os requisitos funcionais
e não funcionais do WMA Travel ERP e os componentes técnicos responsáveis por sua implementação.

Seu objetivo é garantir rastreabilidade completa durante todo o ciclo de vida do sistema,
desde a especificação até a implantação, manutenção e auditoria.

---

## Objetivos

A Matriz de Rastreabilidade possui os seguintes objetivos:

- Garantir rastreabilidade completa
- Facilitar auditorias
- Apoiar homologações
- Auxiliar manutenção evolutiva
- Identificar impactos de mudanças
- Garantir cobertura dos requisitos

---

## Estrutura da Matriz

Cada requisito deverá estar vinculado aos seguintes componentes:

- Módulo do ERP
- Processo de Negócio
- Banco de Dados
- API
- Interface
- Auditoria
- Documentação
- Testes
- Responsável

---

## Identificação dos Requisitos

Todos os requisitos deverão possuir identificação única.

Formato:

```text
REQ-0001
REQ-0002
REQ-0003
```

---

## Estrutura dos Módulos

Os módulos oficiais do ERP são:

| Código  | Módulo                |
| ------- | --------------------- |
| MOD-ADM | Administrativo        |
| MOD-FIN | Financeiro            |
| MOD-FIS | Fiscal                |
| MOD-COM | Comercial             |
| MOD-TUR | Turismo               |
| MOD-BKT | Bike Tour             |
| MOD-RH  | Recursos Humanos      |
| MOD-BI  | Business Intelligence |
| MOD-SEG | Segurança             |
| MOD-CFG | Configuração          |

---

## Matriz de Rastreabilidade

| Requisito | Processo             | Banco          | API         | Interface  | Auditoria | Testes |
| --------- | -------------------- | -------------- | ----------- | ---------- | --------- | ------ |
| REQ-0001  | Cadastro de Clientes | cliente        | /clientes   | Clientes   | Sim       | Sim    |
| REQ-0002  | Cadastro de Empresas | empresa        | /empresas   | Empresas   | Sim       | Sim    |
| REQ-0003  | Fluxo de Caixa       | fluxo_caixa    | /financeiro | Financeiro | Sim       | Sim    |
| REQ-0004  | Contas a Pagar       | contas_pagar   | /financeiro | Financeiro | Sim       | Sim    |
| REQ-0005  | Contas a Receber     | contas_receber | /financeiro | Financeiro | Sim       | Sim    |

---

## Rastreabilidade das Tabelas

Cada tabela deverá possuir vínculo com:

- módulo
- processo
- documentação
- auditoria
- responsável

---

### Exemplo

| Tabela      | Módulo         | Processo           |
| ----------- | -------------- | ------------------ |
| cliente     | Comercial      | Cadastro           |
| empresa     | Administrativo | Empresa            |
| usuario     | Segurança      | Controle de Acesso |
| fluxo_caixa | Financeiro     | Fluxo de Caixa     |

---

## Rastreabilidade das APIs

Cada endpoint deverá possuir:

- módulo
- documentação
- testes
- autenticação
- versão

---

### Exemplo

| Endpoint    | Método | Módulo         |
| ----------- | ------ | -------------- |
| /clientes   | GET    | Comercial      |
| /clientes   | POST   | Comercial      |
| /empresas   | GET    | Administrativo |
| /financeiro | GET    | Financeiro     |

---

## Rastreabilidade das Auditorias

Todas as auditorias deverão indicar:

- requisito atendido
- objeto auditado
- resultado
- evidência

---

### Integração com o Framework DBA

A Matriz de Rastreabilidade integra-se aos seguintes componentes:

- Auditoria Estrutural
- Auditoria Documental
- Auditoria de Segurança
- Auditoria de Performance
- Health Check
- Dashboard Técnico
- Dashboard Executivo

---

## Controle de Mudanças

Toda alteração deverá atualizar:

- requisito
- documentação
- banco de dados
- APIs
- testes
- auditorias
- changelog

---

### Benefícios

A utilização da Matriz de Rastreabilidade proporciona:

- Cobertura completa dos requisitos
- Facilidade de auditoria
- Controle de impacto
- Governança de TI
- Redução de riscos
- Maior qualidade documental
- Apoio à certificação técnica

---

## Apêndice E — Estrutura Completa do Framework DBA

O Framework DBA é o componente responsável pela administração,
padronização, auditoria, monitoramento, governança e certificação técnica do banco de dados PostgreSQL do WMA Travel ERP.

Sua arquitetura foi concebida para permitir evolução contínua, automação das verificações e manutenção simplificada.

---

### Objetivos

O Framework DBA possui os seguintes objetivos:

- Automatizar auditorias
- Padronizar o banco de dados
- Garantir qualidade estrutural
- Monitorar continuamente o ambiente
- Detectar inconsistências
- Automatizar correções
- Gerar indicadores técnicos
- Emitir certificação do banco

---

## Arquitetura Geral

```text
Framework DBA
│
├── CORE
│
├── Auditorias
│
├── Governança
│
├── Segurança
│
├── Performance
│
├── Backup
│
├── Monitoramento
│
├── Certificação
│
├── Dashboard Técnico
│
└── Dashboard Executivo
```

---

## Estrutura de Diretórios

```text
database/

├── 00_Instalacao/

├── 01_Modelagem/

├── 02_Padronizacao/

├── 03_Seeds/

├── 04_Framework_DBA/
│
│   ├── 04_00_Core/
│   │
│   ├── 04_01_Auditoria/
│   │
│   ├── 04_02_Documentacao/
│   │
│   ├── 04_03_Performance/
│   │
│   ├── 04_04_Seguranca/
│   │
│   ├── 04_05_Backup/
│   │
│   ├── 04_06_Monitoramento/
│   │
│   ├── 04_07_Governanca/
│   │
│   ├── 04_08_Certificacao/
│   │
│   └── 04_09_Dashboard/

├── 05_Migrations/

├── 06_Testes/

├── 07_Documentacao/

└── 99_Utilitarios/
```

---

## CORE

O CORE concentra os componentes compartilhados por todo o Framework.

Módulos:

- Configuração
- Utilitários
- Logging
- Tratamento de Erros
- Execução
- Scheduler
- Configurações Gerais
- Constantes

---

## Auditorias

O módulo de Auditoria executa verificações automáticas sobre:

- Estrutura
- Integridade
- Índices
- Constraints
- Documentação
- Segurança
- Backup
- Performance

---

## Documentação

Responsável por validar:

- comentários
- documentação técnica
- dicionário de dados
- rastreabilidade
- arquitetura

---

### Performance

Executa auditorias relacionadas a:

- índices
- consultas
- cache
- VACUUM
- ANALYZE
- estatísticas
- crescimento

---

### Segurança

Audita:

- Roles
- Permissões
- SSL
- LGPD
- RLS
- Objetos públicos
- Auditoria

---

### Backup

Valida:

- Backup diário
- Backup Full
- Restore
- PITR
- Retenção
- Criptografia

---

### Monitoramento

Executa:

- Health Check
- Coleta de métricas
- Alertas
- Dashboard
- Logs

---

### Governança

Valida:

- Versionamento
- Convenções
- Nomenclatura
- Estrutura
- Padrões

---

### Certificação

Responsável por:

- Consolidar auditorias
- Calcular ICB
- Gerar Score Técnico
- Emitir Certificação

---

### Dashboard Técnico

Apresenta:

- Performance
- Segurança
- Estrutura
- Auditorias
- Crescimento
- ICB

---

### Dashboard Executivo

Apresenta:

- Indicadores estratégicos
- Disponibilidade
- Riscos
- Tendências
- Conformidade

---

## Fluxo de Execução

```text
Inicialização

↓

Carregamento do CORE

↓

Leitura das Configurações

↓

Auditoria Estrutural

↓

Auditoria Documental

↓

Auditoria de Segurança

↓

Auditoria de Performance

↓

Auditoria de Backup

↓

Health Check

↓

Plano Automático de Correção

↓

Dashboard

↓

Certificação Técnica

↓

Encerramento
```

---

## Fluxo da Certificação

```text
Auditorias

↓

Validação

↓

Health Check

↓

ICB

↓

Score Técnico

↓

Não Conformidades

↓

Plano de Correção

↓

Revalidação

↓

Certificação
```

---

## Integração com o ERP

O Framework integra-se aos seguintes componentes:

- PostgreSQL
- Backend Python
- FastAPI
- SQLAlchemy
- Alembic
- Power BI
- Dashboard Técnico
- Dashboard Executivo

---

## Integração com CI/CD

Pipeline recomendado:

```text
Commit

↓

Lint SQL

↓

Validação

↓

Testes

↓

Migração

↓

Auditoria

↓

Health Check

↓

Deploy

↓

Certificação
```

---

## Cronograma de Execução

| Processo              | Frequência  |
| --------------------- | ----------- |
| Auditoria Estrutural  | Diária      |
| Auditoria Segurança   | Diária      |
| Auditoria Performance | Diária      |
| Backup                | Diária      |
| Dashboard             | Tempo Real  |
| Certificação          | Sob Demanda |

---

## Indicadores

| Indicador       | Meta    |
| --------------- | ------- |
| Auditorias      | 100%    |
| Backup          | 100%    |
| Health Check    | 100%    |
| ICB             | ≥ 95%   |
| Score Técnico   | ≥ 95%   |
| Disponibilidade | ≥ 99,9% |

---

## Evolução do Framework

## Versão 1

- CORE
- Auditorias
- Dashboard
- Certificação

---

## Versão 2

- IA para análise automática
- Auto Repair
- Dashboards avançados
- Predição de falhas

---

## Versão 3

- Machine Learning
- Capacity Planning
- Self-Healing Database
- Auditoria Inteligente

---

### Benefícios

A arquitetura do Framework DBA proporciona:

- Governança corporativa
- Auditorias automatizadas
- Alta disponibilidade
- Padronização técnica
- Monitoramento contínuo
- Redução de riscos
- Certificação automática
- Escalabilidade
- Facilidade de manutenção
- Integração com CI/CD

---

## Encerramento

O Framework DBA representa a base de governança do banco de dados do WMA Travel ERP.

Sua utilização garante conformidade técnica, rastreabilidade, monitoramento contínuo
e certificação do ambiente PostgreSQL,
apoiando a evolução sustentável do sistema e assegurando elevados padrões de qualidade e confiabilidade.

---

**Copyright © 2026 WMA Travel Ltda.**
**Todos os direitos reservados.**
