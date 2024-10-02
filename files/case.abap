*&---------------------------------------------------------------------*
*& Report /YGA/RTESTE_MB
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /yga/rteste_mb.

*tables: ekpo, anep.

*parameters: p_ebeln type ekpo-ebeln.
*parameters: p_ebelp type ekpo-ebelp.
*parameters: p_anbtr type anep-anbtr.
*PARAMETERS: p_ini TYPE INM_TV_EXTID.

START-OF-SELECTION.

  DATA: lv_nr_filas      TYPE numc2,
        lv_valor         TYPE zvalor,
        lt_system_status TYPE TABLE OF bapi_wbs_mnt_system_status,
        lt_system1       TYPE TABLE OF bapi_wbs_mnt_system_status.

  zcl_ca_fixed_value=>get_value( EXPORTING i_zarea       = /yga/cl_fixed_values=>ac_area
                                           i_zprocesso   = '/YGA/CL_QRFC'
                                           i_campo       = 'NR_FILAS'
                                           i_zocorrencia = /yga/cl_fixed_values=>ac_ocorrencia
                                           i_zcontador   = /yga/cl_fixed_values=>ac_contador
                                 IMPORTING e_val_min     = lv_valor
                                EXCEPTIONS no_data       = 1
                                           OTHERS        = 2 ).

  IF lv_valor IS INITIAL.
    lv_nr_filas = 10.
  ELSE.
    lv_nr_filas = lv_valor.
  ENDIF.

  

  DATA(lo_qrfc) = NEW /yga/cl_qrfc( iv_campo    = '/YGA/SET_DLFL'
                                    iv_nr_filas = lv_nr_filas ).

*  lo_qrfc->set_queue( ).

  APPEND INITIAL LINE TO lt_system_status ASSIGNING FIELD-SYMBOL(<fs_sys>).
  <fs_sys>-wbs_element =  '2800-23C006062-1'.
  <fs_sys>-set_system_status = 'DLFL'.
  APPEND INITIAL LINE TO lt_system_status ASSIGNING <fs_sys>.
  <fs_sys>-wbs_element =  '2800-23C006062-2'.
  <fs_sys>-set_system_status = 'DLFL'.

  LOOP AT lt_system_status ASSIGNING FIELD-SYMBOL(<fs_system_status>).


  lo_qrfc->set_queue( ).

    APPEND INITIAL LINE TO lt_system1 ASSIGNING FIELD-SYMBOL(<fs_wbs>).
    <fs_wbs>-wbs_element = <fs_system_status>-wbs_element.
    <fs_wbs>-set_system_status = 'DLFL'.

    CALL FUNCTION '/YGA/BUS2054_SET_STATUS' IN BACKGROUND TASK DESTINATION 'NONE'
      TABLES
        it_system_status = lt_system1.

      COMMIT WORK.

  ENDLOOP.




*  DATA lr_iniciativa TYPE RANGE OF inm_tv_extid.
*
*  lr_iniciativa = VALUE #( sign = 'I' option = 'EQ' ( low = p_ini ) ).
*
*  SUBMIT /rpm/set_item_icons
*                WITH p_simu   = ' '
*                WITH p_update = 'X'
*                WITH p_delete = ' '
*                WITH p_lang   = sy-langu
*                WITH p_iniid  IN lr_iniciativa and RETURN EXPORTING LIST TO MEMORY.


*  DATA: lt_rsparams TYPE rsparams_tt,
*        ls_rsparams TYPE rsparams.
*
*  FREE: lt_rsparams[].
*  CLEAR: ls_rsparams.
*
*  ls_rsparams-kind   = 'S'.
*  ls_rsparams-sign   = 'I'.
*  ls_rsparams-option = 'EQ'.
*  ls_rsparams-selname = 'S_AUFNR'.
*  ls_rsparams-low     = p_aufnr.
*  APPEND ls_rsparams TO lt_rsparams.
*
**   Programa para corrigir falsos compromissos nas ordens
*  SUBMIT /yga/reg_custos
*    WITH SELECTION-TABLE lt_rsparams
*    WITH p_prg1 = 'X'
*     AND RETURN
*   EXPORTING LIST TO MEMORY.


*  data lv_ebeln type string.

*  if  sign( p_anbtr ) eq '1'. "Valor positivo
*    write '+'.
*  elseif  sign( p_anbtr ) eq '1-'. "Valor negativo
*    write '-'.
*  endif.
*
* p_anbtr = p_anbtr * -1.
*  write p_anbtr.


*  data: lt_itemx                  type standard table of bapimeoutitemx,
*        lt_item                   type standard table of bapimeoutitem,
*        ls_bapi_te_meoutitem      type bapi_te_meoutitem,
*        ls_bapi_te_meoutitemx     type bapi_te_meoutitemx,
*        lt_extensionin            type table of bapiparex,
*        ls_extensionin            type bapiparex,
*        ls_extensionin_mereqitemx type bapiparex,
*        lt_return                 type standard table of bapiret2.
*
*  append initial line to lt_item assigning field-symbol(<fs_item>).
*  <fs_item>-item_no = p_ebelp.
*
*  append initial line to lt_itemx assigning field-symbol(<fs_itemx>).
*  <fs_itemx>-item_no  = p_ebelp.
*  <fs_itemx>-item_nox = abap_true.
*
*  ls_bapi_te_meoutitem-item_no = p_ebelp.
*  ls_bapi_te_meoutitem-zznao_apli_sinergie = abap_true.
*  ls_bapi_te_meoutitemx-item_no = p_ebelp.
*  ls_bapi_te_meoutitemx-zznao_apli_sinergie = abap_true.
*
*  ls_extensionin-structure = 'BAPI_TE_MEOUTITEM'.
*
*  call method cl_abap_container_utilities=>fill_container_c
*    exporting
*      im_value               = ls_bapi_te_meoutitem
*    importing
*      ex_container           = ls_extensionin+30
*    exceptions
*      illegal_parameter_type = 1
*      others                 = 2.
*
*  lt_extensionin = value #( ( structure   = ls_extensionin-structure
*                              valuepart1  = ls_extensionin-valuepart1
*                              valuepart2  = ls_extensionin-valuepart2 )
*
*                            ( structure   = 'BAPI_TE_MEOUTITEMX'
*                              valuepart1  = ls_bapi_te_meoutitemx ) ).
*
*
*  call function 'BAPI_CONTRACT_CHANGE'
*    exporting
*      purchasingdocument = p_ebeln
*    tables
*      item               = lt_item
*      itemx              = lt_itemx
*      extensionin        = lt_extensionin
*      return             = lt_return.
*
*  concatenate p_ebeln '/' p_ebelp into lv_ebeln.
*
*  read table lt_return transporting no fields with key type = 'E'.
*  if sy-subrc = 0.
*    write: 'Não foi possível atualizado o pedido de compra/item: ', lv_ebeln.
*  else.
*    call function 'BAPI_TRANSACTION_COMMIT'
*      exporting
*        wait = 'X'.
*    write: 'Pedido de compra/item atualizado com sucesso: ', lv_ebeln.
*  endif.