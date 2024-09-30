# Queue process
 Processamento de filas SMQ2.

 
![Static Badge](https://img.shields.io/badge/development-abap-blue)
![GitHub commit activity (branch)](https://img.shields.io/github/commit-activity/t/edmilson-nascimento/queue-process)
![Static Badge](https://img.shields.io/badge/gabriel_alencar-abap-pink)

> 🗘 Este documento, assim como o negócio, está em constante fase de melhoria e adaptação.



### Glossário

| Sigla | Significado | Descrição |
| :--- |:---------- |:---------- |
| BC|Business Consulting | ~~Find Clarity in Chaos~~ ABAP, Desenvolvedor SAP, Consultor ABAP, SAP DEV|



### Fluxo da solução

```mermaid
%%{ init: { 'flowchart': { 'curve': 'basis' } } }%%
flowchart TB

    Begin((" ")):::startClass --> service-now([Processamento])
    service-now --> Atendimento-BC(["Lista de itens"])
    Atendimento-BC --> Q1{" "}

    Q1 -- Sim --> Quermesse("Adic. na fila") 
            --> End
    Q1 -- Não -->

End(((" "))):::endClass
```


## Pontos de atenção 📝

- A chamada da função deve ser `IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT`
- 
