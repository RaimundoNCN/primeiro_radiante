# Primeiro Radiante — documentação de produto e engenharia

Este diretório contém o planejamento anterior à implementação do **Primeiro
Radiante**, um aplicativo de cálculos, exploração matemática e simulação de
cenários inspirado conceitualmente na ficção científica de *Fundação*.

> Nota de identidade: nos livros, o personagem se chama **Hari Seldon**. O
> produto será uma obra original inspirada no conceito de uma interface
> matemática avançada; não copiará texto, imagens, símbolos, trilha ou design de
> adaptações existentes. O uso público/comercial do nome deve passar por análise
> jurídica e, se necessário, receber uma marca original antes da publicação.

## Decisão de isolamento do projeto

O **Primeiro Radiante é um produto totalmente independente da Nuvem / Creator
Store**. Este é o repositório próprio do aplicativo.

A implementação terá obrigatoriamente:

- diretório e repositório Git próprios;
- novo projeto Flutter e novo identificador de pacote;
- dependências, testes, pipeline e versionamento próprios;
- banco de dados, migrações, ambientes e segredos próprios;
- identidade visual, autenticação, telemetria e publicação próprias;
- nenhuma importação ou dependência do código da Nuvem.

O repositório da Nuvem não será convertido em monorepo, não receberá o
aplicativo e não terá seu histórico ou código substituídos.

## Ordem de leitura e execução

1. [Planejamento do produto](./PLANEJAMENTO_PRODUTO.md)
2. [Experiência de desbloqueio](./GESTO_DESBLOQUEIO.md)
3. [Arquitetura técnica](./ARQUITETURA_TECNICA.md)
4. [Modelo de dados SQL](./MODELO_DADOS_SQL.md)
5. [Plano de implementação e validação](./PLANO_IMPLEMENTACAO.md)

## Decisões já registradas

- Aplicação mobile em Flutter exclusiva para Android e iOS.
- Tema escuro com visualização matemática dourada e animações procedurais.
- Desbloqueio por um círculo desenhado na tela seguido de três toques.
- O gesto é uma experiência de entrada, não um substituto para autenticação
  segura, biometria ou PIN.
- Cálculos determinísticos são locais e reproduzíveis.
- Recursos de IA explicam, sugerem e estruturam problemas, mas não substituem o
  motor matemático nem alteram resultados silenciosamente.
- SQLite local-first para projetos, histórico e cenários; sincronização remota é
  opcional e posterior.
- Nenhuma previsão social ou histórica será apresentada como certeza científica.

## Portões antes de escrever código de produção

- Criar e inicializar o repositório independente do Primeiro Radiante.
- Aprovar nome/marca e limites da inspiração em *Fundação*.
- Fechar o escopo do MVP e escolher as bibliotecas matemáticas após um spike.
- Validar o protótipo do gesto em aparelhos físicos de tamanhos diferentes.
- Definir se haverá conta e sincronização no MVP.
- Aprovar política de privacidade para dados enviados a um provedor de IA.
