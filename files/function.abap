FUNCTION /YGA/QUEUE
  IMPORTING
    VALUE(IM_INFO) TYPE SYMSGV OPTIONAL.



  CONSTANTS:
    BEGIN OF lc_log,
      object    TYPE balobj_d  VALUE 'ZTEMP',
      subobject TYPE balsubobj VALUE 'TEMP',
    END OF lc_log,
    lc_expirate TYPE i VALUE 7.



  DATA(message_list) = cf_reca_message_list=>create( id_object    = lc_log-object
                                                     id_subobject = lc_log-subobject
                                                     id_deldate   = |{ sy-datum + lc_expirate }| ).
  IF message_list IS NOT BOUND.
    RETURN.
  ENDIF.

  message_list->add( id_msgty = if_xo_const_message=>info
                     id_msgid = '>0'
                     id_msgno = '000'
                     id_msgv1 = |Item has been done. |
                     id_msgv2 = im_info
                     id_msgv3 = |({ sy-uname } { sy-datum DATE = USER } { sy-uzeit TIME = USER }).| ).

  message_list->store( ).

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = abap_true.


ENDFUNCTION.