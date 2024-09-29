FUNCTION /YGA/QUEUE
  IMPORTING
    VALUE(IM_TIME) TYPE I.



  CONSTANTS:
    BEGIN OF lc_log,
      object    TYPE balobj_d  VALUE '/YGA/JUMP',
      subobject TYPE balsubobj VALUE 'TRANSP_CTRL',
    END OF lc_log,
    lc_expirate TYPE i VALUE 90.

  DATA(process_time) = COND #( WHEN im_time IS INITIAL
                                 THEN 7
                                 ELSE im_time ).

  WAIT UP TO process_time SECONDS.

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
                     id_msgv2 = |({ sy-uname } { sy-datum DATE = USER } { sy-uzeit TIME = USER }).| ).

  message_list->store( ).

*    IF sy-subrc = 0.
*      COMMIT WORK AND WAIT.
*    ENDIF.

ENDFUNCTION.