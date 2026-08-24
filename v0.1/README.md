# Queue process
 Processamento de filas SMQ2.

 ~~No momento, eu penso que seja uma boa ideia fazer disso um post no SAP Blogs, mas essa animação vai por água abaixo em alguns dias~~
 
![Static Badge](https://img.shields.io/badge/development-abap-blue?style=flat)
![Static Badge](https://img.shields.io/badge/ABAP_OO-object_oriented-teal?style=flat)
![Static Badge](https://img.shields.io/badge/SAP-ERP-E52731?style=flat)
![Static Badge](https://img.shields.io/badge/development-ABAP_logging-blue?style=flat)
![Static Badge](https://img.shields.io/badge/IDE-Eclipse_ADT-2C2255?style=flat)
![Static Badge](https://img.shields.io/badge/Platform-GitHub-181717?style=flat)
![GitHub commit activity](https://img.shields.io/github/commit-activity/t/edmilson-nascimento/queue-process?style=flat)
![Static Badge](https://img.shields.io/badge/SAP-On_Premise-4666FF?style=flat)

> 🗘 Este documento, assim como o negócio, está em constante fase de melhoria e adaptação.



## Glossário

| Sigla | Significado | Descrição |
|-----|-----------|------------|
| BC |Business Consulting | ~~Find Clarity in Chaos~~ ABAP, Desenvolvedor SAP, Consultor ABAP, SAP DEV|
 FM | Function Module ||



## Fluxo da solução

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

### Processamento
Para o processamento de exemplo, vamos criar uma função que terá como única função salvar um log de processamento. ~~Isso basicamente diz: passou aqui!~~
A função tem de ser criada com **Tipo de processo: Módulo de acesso remoto**.

![N|Solid](files/img/tipo_funcao.png)

A chamada da função, por sua vez também é diferente. Segundo o que foi compartilhado com o respeitado consultor SAP ABAP Daniel Marques, isso vai atender um dos objetivos que é _escolher o servidor que estiver mais livre (em teoria)_.

Abaixo um exemplo de como ficaria a chamada da função.

```abap

    CALL FUNCTION 'Z_QUEUE'
      IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT

```

## Pontos de atenção 📝

- A chamada da função deve ser `IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT`
-
