REPORT ytest.

CLASS lcl_queue DEFINITION CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS constructor.

    METHODS add_item.

    CLASS-METHODS add_log
      IMPORTING im_guid TYPE sysuuid_c32.

  PRIVATE SECTION.

    METHODS get_guid
      RETURNING VALUE(result) TYPE sysuuid_c32.

ENDCLASS.

CLASS lcl_queue IMPLEMENTATION.

  METHOD constructor.
  ENDMETHOD.

  METHOD add_item.

    DATA lv_nr_filas TYPE numc2 VALUE 5.

    DATA(lo_qrfc) = NEW /yga/cl_qrfc( iv_campo    = '/YGA/_'
                                      iv_nr_filas = lv_nr_filas ).

    lo_qrfc->set_queue( ).

    CALL FUNCTION 'Z_QUEUE'
      IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT
      EXPORTING guid = me->get_guid( ).

    COMMIT WORK.

  ENDMETHOD.

  METHOD add_log.

    CONSTANTS:
      BEGIN OF lc_log,
        object    TYPE balobj_d  VALUE 'ZTEMP',
        subobject TYPE balsubobj VALUE 'TEMP',
      END OF lc_log.

    DATA(message_list) = cf_reca_message_list=>create( id_object    = lc_log-object
                                                       id_subobject = lc_log-subobject
                                                       id_extnumber = ''
                                                       id_deldate   = |{ sy-datum + 7 }| ).
    IF message_list IS NOT BOUND.
      RETURN.
    ENDIF.

    message_list->add( id_msgty = if_xo_const_message=>info
                       id_msgid = '>0'
                       id_msgno = '000'
                       id_msgv1 = |GUID { im_guid }.|
                       id_msgv2 = |({ sy-uname } { sy-datum DATE = USER } { sy-uzeit TIME = USER }).| ).

    message_list->store( ).

    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.

  METHOD get_guid.
    result = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
  ENDMETHOD.

ENDCLASS.


INITIALIZATION.

  DATA times TYPE i VALUE 350.

  DO times TIMES.
    NEW lcl_queue( )->add_item( ).
  ENDDO.