# Finanças

Aplicativo Android para gestão financeira pessoal, desenvolvido com Flutter.

## Estrutura

```text
lib/
  app/                  Configuração do app e tema
  core/
    database/           Acesso e versionamento do SQLite
  features/
    dashboard/
      presentation/
        view/           Telas
        viewmodel/      Estado e lógica de apresentação
```

## Executar

```bash
flutter pub get
flutter run
```

O banco SQLite é criado sob demanda em `finances.db`. O painel inicial apresenta
valores vazios; a integração de lançamentos será adicionada nas próximas etapas.
