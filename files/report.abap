*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT queue.

CLASS z_cl_queue DEFINITION
CREATE
  PUBLIC
  FINAL
 .

  PUBLIC SECTION.

    DATA gv_qname TYPE trfcqin-qname .
    DATA gv_registered TYPE abap_bool .

    METHODS constructor
      IMPORTING
        VALUE(iv_campo)    TYPE name_feld
        VALUE(iv_sufixo)   TYPE name_feld OPTIONAL
        VALUE(iv_nr_filas) TYPE numc2 OPTIONAL
        !iv_qname          TYPE trfcqin-qname OPTIONAL
      EXCEPTIONS
        not_found .
    METHODS set_delay
      IMPORTING
        VALUE(iv_atraso) TYPE i OPTIONAL
      RETURNING
        VALUE(qin_count) TYPE trfcqin-qcount .
    METHODS set_queue
      IMPORTING
        VALUE(qin_count) TYPE trfcqin-qcount OPTIONAL .
    METHODS get_queue_name
      RETURNING
        VALUE(rv_value) TYPE trfcqin-qname .
    METHODS set_queue_name
      IMPORTING
        !iv_value TYPE trfcqin-qname .
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF tt_qview,
        qname     TYPE trfcqin-qname,
        qrfcdatum TYPE trfcqin-qrfcdatum,
        qrfcuzeit TYPE trfcqin-qrfcuzeit,
      END OF tt_qview.
ENDCLASS.



CLASS z_cl_queue IMPLEMENTATION.


  METHOD constructor.

    DATA: lv_valor     TYPE zvalor,
          lv_valor2    TYPE zvalor,
          lv_limite(2) TYPE n,
          lv_cont(1)   TYPE n,
          lv_last      TYPE i VALUE '10',
          lv_tipo      TYPE sy-input,
          lv_register  TYPE sy-subrc,
          lv_max       TYPE qf00-ran_int,
          lv_rand      TYPE qf00-ran_int,
          lt_qview     TYPE TABLE OF tt_qview.

*    zcl_ca_fixed_value=>get_value( EXPORTING i_zarea       = /yga/cl_fixed_values=>ac_area
*                                             i_zprocesso   = '/YGA/CL_QRFC'
*                                             i_campo       = iv_campo
*                                             i_zocorrencia = /yga/cl_fixed_values=>ac_ocorrencia
*                                             i_zcontador   = /yga/cl_fixed_values=>ac_contador
*                                   IMPORTING e_val_min     = lv_valor
*                                  EXCEPTIONS no_data       = 1
*                                             OTHERS        = 2 ).
*
*    IF  sy-subrc    EQ 0.
*
*
*      IF iv_nr_filas IS INITIAL.
*
*        zcl_ca_fixed_value=>get_value( EXPORTING i_zarea       = /yga/cl_fixed_values=>ac_area
*                                                 i_zprocesso   = '/YGA/CL_QRFC'
*                                                 i_campo       = 'NR_FILAS'
*                                                 i_zocorrencia = /yga/cl_fixed_values=>ac_ocorrencia
*                                                 i_zcontador   = /yga/cl_fixed_values=>ac_contador
*                                       IMPORTING e_val_min     = lv_valor2
*                                      EXCEPTIONS no_data       = 1
*                                                 OTHERS        = 2 ).
*        IF sy-subrc EQ 0.
*          lv_limite = lv_valor2.
*        ENDIF.
*
*      ELSE.
*
*        lv_limite = iv_nr_filas.
*
*      ENDIF.
*
*      zcl_ca_fixed_value=>get_value( EXPORTING i_zarea       = /yga/cl_fixed_values=>ac_area
*                                               i_zprocesso   = '/YGA/CL_QRFC'
*                                               i_campo       = 'TP_FILAS'
*                                               i_zocorrencia = /yga/cl_fixed_values=>ac_ocorrencia
*                                               i_zcontador   = /yga/cl_fixed_values=>ac_contador
*                                     IMPORTING e_val_min     = lv_valor2
*                                    EXCEPTIONS no_data       = 1
*                                               OTHERS        = 2 ).
*      IF sy-subrc EQ 0.
*        lv_tipo = lv_valor2.
*      ENDIF.

    lv_limite = iv_nr_filas.
    lv_tipo = lv_valor2 = 'D'.

    IF iv_qname IS INITIAL.

* Valida se fila está livre
      DO lv_limite TIMES.

        IF iv_sufixo IS NOT INITIAL.

          gv_qname = |{ lv_valor }{ iv_sufixo }|.

        ELSE.

          ADD 1 TO lv_cont.
          gv_qname = |{ lv_valor }{ lv_cont }|.

        ENDIF.

        SELECT SINGLE qname, qrfcdatum, qrfcuzeit
          FROM trfcqin
          INTO @DATA(ls_qview)
         WHERE qname EQ @gv_qname.

        IF sy-subrc NE 0.
* Fila não está a correr
          DATA(lv_empty) = abap_true.
          EXIT.
        ELSE.
          APPEND INITIAL LINE TO lt_qview ASSIGNING FIELD-SYMBOL(<fs_qview>).
          <fs_qview> = VALUE tt_qview( qname     = ls_qview-qname
                                       qrfcdatum = ls_qview-qrfcdatum
                                       qrfcuzeit = ls_qview-qrfcuzeit ).
        ENDIF.
      ENDDO.

      IF lv_empty EQ abap_false.

        SELECT *
          FROM trfcqin
          INTO TABLE @DATA(lt_qrfcqin)
           FOR ALL ENTRIES IN @lt_qview
         WHERE qname EQ @lt_qview-qname.

        IF sy-subrc EQ 0.
        ENDIF.

        lv_max = lv_limite.
        CALL FUNCTION 'QF05_RANDOM_INTEGER'
          EXPORTING
            ran_int_max   = lv_max
*           RAN_INT_MIN   = 1
          IMPORTING
            ran_int       = lv_rand
          EXCEPTIONS
            invalid_input = 1
            OTHERS        = 2.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

        IF iv_sufixo IS NOT INITIAL.
          gv_qname = |{ lv_valor }{ iv_sufixo }|.
        ELSE.
          gv_qname = |{ lv_valor }{ lv_rand }|.
        ENDIF.

* Trata filas em erro
        DATA(lt_aux) = lt_qrfcqin[].
        DELETE lt_aux WHERE qstate NE 'SYSFAIL'.
        LOOP AT lt_aux INTO DATA(ls_aux).

          DATA(ls_tid) = VALUE arfctid( arfcipid   = ls_aux-arfcipid
                                        arfcpid    = ls_aux-arfcpid
                                        arfctime   = ls_aux-arfctime
                                        arfctidcnt = ls_aux-arfctidcnt ).
* Elimina processo em erro e guarda no log
          CALL FUNCTION 'TRFC_QIN_DELETE_LUW'
            EXPORTING
              tid           = ls_tid
              write_sys_log = abap_true
            EXCEPTIONS
              error_message = 1
              OTHERS        = 2.

          IF sy-subrc EQ 0.
          ENDIF.
* Reinicia fila, em paralelo para não prender o processo atual
          CALL FUNCTION 'TRFC_QIN_RESTART'
            STARTING NEW TASK 'RESTART' DESTINATION IN GROUP DEFAULT
            EXPORTING
              qname                = ls_aux-qname
              force                = abap_true
            EXCEPTIONS
              invalid_parameter    = 1
              system_failed        = 2
              communication_failed = 3
              OTHERS               = 4.

          IF sy-subrc NE 0.
          ENDIF.

        ENDLOOP.

      ENDIF.

    ELSE.

      gv_qname = iv_qname.

    ENDIF.

* Valida se fila está registrada (SMQR)
    CALL FUNCTION 'QIWK_CHECK_REGISTER'
      EXPORTING
        qname    = gv_qname
      IMPORTING
        register = lv_register.

    IF sy-subrc NE 0
    OR lv_register EQ 0.
* Registra fila e libera
* STARTING NEW TASK to avoid dump in BADI's IN_UPDATE
      CALL FUNCTION 'QIWK_REGISTER'
        STARTING NEW TASK 'QIWK_REGISTER' DESTINATION IN GROUP DEFAULT
        EXPORTING
          qname              = gv_qname
          exemode            = lv_tipo      "Batch/Dialogo
        EXCEPTIONS
          invalid_queue_name = 1
          invalid_exe_mode   = 2
          OTHERS             = 3.

      IF sy-subrc NE 0.
      ENDIF.

    ENDIF.

    gv_registered = abap_true.

*    ELSE.
*
*      gv_qname = |{ iv_campo }{ sy-uzeit }|.
*      gv_registered = abap_false.
*
*    ENDIF.

  ENDMETHOD.


  METHOD get_queue_name.

    rv_value = gv_qname.

  ENDMETHOD.


  METHOD set_delay.

    DATA: lv_datum    TYPE sy-datum,
          lv_start_hr TYPE tbtcjob-sdlstrttm,
          lv_uzeit    TYPE sy-uzeit,
          lv_atraso   TYPE i.


    IF iv_atraso IS INITIAL.
      lv_atraso = '0300'.
    ELSE.
      lv_atraso = iv_atraso.
    ENDIF.

    IF sy-uzeit GE '235900'.
      lv_datum = sy-datum + 1.
      lv_start_hr = lv_uzeit + iv_atraso.
    ELSE.
      lv_datum    = sy-datum.
      lv_start_hr = sy-uzeit + iv_atraso.
    ENDIF.

    CALL FUNCTION '/SDF/MON_CALC_QCOUNT'
      EXPORTING
        datum  = lv_datum
        time   = lv_start_hr
      IMPORTING
        qcount = qin_count.

*  call function 'START_OF_BACKGROUNDTASK'
*    exporting
*      startdate = lv_datum
*      starttime = lv_start_hr.

  ENDMETHOD.


  METHOD set_queue.
*** Chamar a fila pra cada RFC - QRFC
* SM58 não exibe
* SMQ2 a fila permanece enquanto não correr tudo
* SMQ1 a fila permanece enquanto não correr tudo
*** Chamar a fila só uma vez, as seguintes ficam como TRFC
* SM58 fica a fila inteira escalonada para ambos
* SMQ1 a fila permanece enquanto não correr tudo
* SMQ2 a fila some depois que executa a primeira

* INBOUND ou OUTBOUND
* IN BACKGROUND TASK DESTINATION lv_dest                  - Erro para a fila inteira
* IN BACKGROUND TASK DESTINATION lv_dest AS SEPARATE UNIT - Erro para a linha

    IF gv_registered EQ abap_true.
* Fila inbound (SMQ2)
      CALL FUNCTION 'TRFC_SET_QIN_PROPERTIES'
        EXPORTING
          qin_name  = gv_qname
          qin_count = qin_count.

    ELSE.
* Fila outbound (SMQ1)
      CALL FUNCTION 'TRFC_SET_QUEUE_NAME'
        EXPORTING
          qname = gv_qname.

    ENDIF.

  ENDMETHOD.


  METHOD set_queue_name.

    gv_qname = iv_value.

  ENDMETHOD.
ENDCLASS.


INITIALIZATION .

  " Recuperando dados de testes
  SELECT carrid, connid, fldate, price, currency, planetype
    INTO TABLE @DATA(lt_data)
    FROM sflight
    UP TO 2 ROWS.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  DATA(go_queue_rfc) = NEW z_cl_queue( iv_campo    = '/YGA/MASS_SITRD'
                                       iv_nr_filas = 10 ).
  IF go_queue_rfc IS NOT BOUND.
    RETURN.
  ENDIF.

  " inicializando a fila disponivel
  go_queue_rfc->set_queue( ).

  " adicionando os registro na fila de processamento
  LOOP AT lt_data INTO DATA(ls_data).

    CALL FUNCTION '/YGA/QUEUE'
      IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT
      EXPORTING
        im_info = CONV symsgv( |{ ls_data-carrid } { ls_data-connid } { ls_data-currency } { ls_data-planetype }| ).

  ENDLOOP.


  COMMIT WORK.