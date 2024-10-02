# Queue process
 Processamento de filas SMQ2.

 ~~no momento, eu penso que seja uma boa ideia fazer disso um post no SAP Blogs, mas essa animação vai por agua em alguns dias~~

 
![Static Badge](https://img.shields.io/badge/development-abap-blue)
![GitHub commit activity (branch)](https://img.shields.io/github/commit-activity/t/edmilson-nascimento/queue-process)
![Static Badge](https://img.shields.io/badge/gabriel_alencar-abap-orange)
![Static Badge](https://img.shields.io/badge/daniel_marques-abap-green)
![Static Badge](https://img.shields.io/badge/poo-abap-teal)

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
Para o processamento de exemplo, vamos criar uma função que tera como unida função salvar um log de processamento. ~~isso basicamente diz: passou aqui!~~
A função tem de ser criada com **Tipo de processo: Módulo de acesso remoto**.

![N|Solid](files/img/tipo_funcao.png)

A chamada da função, por sua vez tambem é diferente. Segundo o que foi compartilhado com o respeitado consultor SAP ABAP Daniel Marques, isso vai atender um dos objetos que é _escolher o servidor que estiver mais livre (em teoria)_.

Abaixo um exemplo de como ficaria a chamada da função.

```abap

    CALL FUNCTION 'Z_QUEUE'
      IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT

```

## Pontos de atenção 📝

- A chamada da função deve ser `IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT`
- 
