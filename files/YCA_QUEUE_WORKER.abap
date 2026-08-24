FUNCTION yca_queue_worker
  IMPORTING
    VALUE(iv_guid) TYPE sysuuid_c32.



  DATA(lo_message_list) = cf_reca_message_list=>create(
    id_object    = 'YCA_QUEUE'
    id_subobject = 'WORKER'
    id_deldate   = |{ sy-datum + 7 }| ).

  IF lo_message_list IS NOT BOUND.
    RETURN.
  ENDIF.

  lo_message_list->add(
    id_msgty = if_xo_const_message=>info
    id_msgid = '>0'
    id_msgno = '000'
    id_msgv1 = |Item { iv_guid } processed.|
    id_msgv2 = |({ sy-uname } { sy-datum DATE = USER } { sy-uzeit TIME = USER }).| ).

  lo_message_list->store( ).

* Keeps the LUW visibly "running" in SMQ2 so the queue throttling can be observed
  WAIT UP TO 2 SECONDS.

  COMMIT WORK AND WAIT.
ENDFUNCTION.
