# Finanças

Aplicativo Android para gestão financeira pessoal, desenvolvido com Flutter.

## Estrutura

```text
lib/
  app/                  Configuração do app e tema
  core/
    database/           Acesso e versionamento do SQLite
  features/
    transactions/
      data/             Persistência dos lançamentos e despesas fixas
      domain/           Modelo de movimentação financeira
    dashboard/
      presentation/
        view/           Telas
        viewmodel/      Estado e lógica de apresentação
    upload/
      data/             Extração e leitura de extratos Itaú em PDF
      presentation/
        view/           Seleção e importação do extrato
        viewmodel/      Estado da importação
```

## Executar

```bash
flutter pub get
flutter run
```

O banco SQLite é criado sob demanda em `finances.db`. O painel inicial apresenta
o saldo líquido das movimentações, entradas e despesas do mês e os lançamentos
recentes. Na aba **Upload**, selecione um extrato Itaú em PDF: o arquivo é lido
localmente, e entradas e despesas são salvas no SQLite. Linhas “SALDO DO DIA”
não são importadas; reimportações ignoram lançamentos já salvos.

Em **Lançamento manual**, marque **Despesa fixa** para repetir a despesa nos
meses seguintes, a partir do mês informado. No painel, navegue entre os meses
para consultar os gastos e use o ícone de edição para ajustar o valor. Alterar
uma despesa fixa afeta somente o mês selecionado.
