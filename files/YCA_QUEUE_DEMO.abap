REPORT yca_queue_demo.

CLASS lcl_queue_dispatcher DEFINITION CREATE PUBLIC FINAL.

  PUBLIC SECTION.

    DATA gv_queue_name       TYPE trfcqin-qname READ-ONLY.
    DATA gv_queue_registered TYPE abap_bool READ-ONLY.

    "! <p class="shorttext synchronized" lang="en">Picks/creates a queue name and registers it in SMQR (SMQ2)</p>
    "! @parameter iv_queue_prefix | <p class="shorttext synchronized" lang="en">Queue-name prefix</p>
    "! @parameter iv_queue_suffix | <p class="shorttext synchronized" lang="en">Fixed suffix; when set, skips the round-robin/random distribution</p>
    "! @parameter iv_queue_count | <p class="shorttext synchronized" lang="en">Number of parallel queues to distribute across (default 1)</p>
    "! @parameter iv_execution_mode | <p class="shorttext synchronized" lang="en">SMQR execution mode: 'D' Dialog / 'B' Batch (default 'D')</p>
    "! @parameter iv_queue_name | <p class="shorttext synchronized" lang="en">Explicit queue name; when set, skips name selection entirely</p>
    METHODS constructor
      IMPORTING
        VALUE(iv_queue_prefix)    TYPE name_feld
        VALUE(iv_queue_suffix)    TYPE name_feld OPTIONAL
        VALUE(iv_queue_count)     TYPE numc2 OPTIONAL
        VALUE(iv_execution_mode)  TYPE sy-input DEFAULT 'D'
        !iv_queue_name            TYPE trfcqin-qname OPTIONAL.

    "! <p class="shorttext synchronized" lang="en">Computes the QIN_COUNT needed to start processing after a given delay</p>
    "! @parameter iv_delay_seconds | <p class="shorttext synchronized" lang="en">Delay in seconds before the queue may start processing (default 300)</p>
    "! @parameter rv_qin_count | <p class="shorttext synchronized" lang="en">Resulting QIN_COUNT to pass into SET_QUEUE</p>
    METHODS set_delay
      IMPORTING VALUE(iv_delay_seconds) TYPE i DEFAULT 300
      RETURNING VALUE(rv_qin_count)     TYPE trfcqin-qcount.

    "! <p class="shorttext synchronized" lang="en">Tags the current LUW so the next queued RFC call lands in this queue</p>
    "! @parameter iv_qin_count | <p class="shorttext synchronized" lang="en">Optional QIN_COUNT (e.g. from SET_DELAY) to defer processing</p>
    METHODS set_queue
      IMPORTING VALUE(iv_qin_count) TYPE trfcqin-qcount OPTIONAL.

    "! <p class="shorttext synchronized" lang="en">Returns the queue name selected/assigned by the constructor</p>
    METHODS get_queue_name RETURNING VALUE(rv_queue_name) TYPE trfcqin-qname.

    "! <p class="shorttext synchronized" lang="en">Overrides the queue name selected by the constructor</p>
    "! @parameter iv_queue_name | <p class="shorttext synchronized" lang="en">Queue name to use instead</p>
    METHODS set_queue_name IMPORTING iv_queue_name TYPE trfcqin-qname.

  PRIVATE SECTION.

    TYPES: BEGIN OF ts_queue_snapshot,
             qname     TYPE trfcqin-qname,
             qrfcdatum TYPE trfcqin-qrfcdatum,
             qrfcuzeit TYPE trfcqin-qrfcuzeit,
           END OF ts_queue_snapshot.

ENDCLASS.


CLASS lcl_queue_dispatcher IMPLEMENTATION.

  METHOD constructor.

    DATA: lv_sequence_number     TYPE n LENGTH 1,
          lv_registration_status TYPE sy-subrc,
          lv_random_upper_bound  TYPE qf00-ran_int,
          lv_random_queue_index TYPE qf00-ran_int,
          lt_queue_snapshot     TYPE TABLE OF ts_queue_snapshot,
          lv_queue_name_available TYPE abap_bool.

    DATA(lv_queue_count) = COND numc2( WHEN iv_queue_count IS NOT INITIAL THEN iv_queue_count ELSE 1 ).

    IF iv_queue_name IS NOT INITIAL.

      gv_queue_name = iv_queue_name.

    ELSE.

      " Check which queue name is currently free
      DO lv_queue_count TIMES.

        IF iv_queue_suffix IS NOT INITIAL.
          gv_queue_name = |{ iv_queue_prefix }{ iv_queue_suffix }|.
        ELSE.
          lv_sequence_number = lv_sequence_number + 1.
          gv_queue_name = |{ iv_queue_prefix }{ lv_sequence_number }|.
        ENDIF.

        SELECT SINGLE qname, qrfcdatum, qrfcuzeit
          FROM trfcqin
          INTO @DATA(ls_queue_snapshot)
         WHERE qname EQ @gv_queue_name.

        IF sy-subrc NE 0.
          lv_queue_name_available = abap_true.
          EXIT.
        ELSE.
          APPEND VALUE #( qname     = ls_queue_snapshot-qname
                           qrfcdatum = ls_queue_snapshot-qrfcdatum
                           qrfcuzeit = ls_queue_snapshot-qrfcuzeit ) TO lt_queue_snapshot.
        ENDIF.

        " A fixed suffix always produces the same name - looping further is pointless
        IF iv_queue_suffix IS NOT INITIAL.
          EXIT.
        ENDIF.

      ENDDO.

      IF lv_queue_name_available EQ abap_false.

        SELECT *
          FROM trfcqin
          INTO TABLE @DATA(lt_queue_entries)
           FOR ALL ENTRIES IN @lt_queue_snapshot
         WHERE qname EQ @lt_queue_snapshot-qname.

        lv_random_upper_bound = lv_queue_count.

        CALL FUNCTION 'QF05_RANDOM_INTEGER'
          EXPORTING
            ran_int_max   = lv_random_upper_bound
          IMPORTING
            ran_int       = lv_random_queue_index
          EXCEPTIONS
            invalid_input = 1
            OTHERS        = 2.

        gv_queue_name = COND #( WHEN iv_queue_suffix IS NOT INITIAL THEN |{ iv_queue_prefix }{ iv_queue_suffix }|
                                                                     ELSE |{ iv_queue_prefix }{ lv_random_queue_index }| ).

        " Restart queues stuck in SYSFAIL without blocking the current process
        LOOP AT lt_queue_entries INTO DATA(ls_failed_queue_entry) WHERE qstate = 'SYSFAIL'.

          CALL FUNCTION 'TRFC_QIN_DELETE_LUW'
            EXPORTING
              tid           = VALUE arfctid( arfcipid   = ls_failed_queue_entry-arfcipid
                                              arfcpid    = ls_failed_queue_entry-arfcpid
                                              arfctime   = ls_failed_queue_entry-arfctime
                                              arfctidcnt = ls_failed_queue_entry-arfctidcnt )
              write_sys_log = abap_true
            EXCEPTIONS
              error_message = 1
              OTHERS        = 2.

          CALL FUNCTION 'TRFC_QIN_RESTART'
            STARTING NEW TASK 'RESTART' DESTINATION IN GROUP DEFAULT
            EXPORTING
              qname                = ls_failed_queue_entry-qname
              force                = abap_true
            EXCEPTIONS
              invalid_parameter    = 1
              system_failed        = 2
              communication_failed = 3
              OTHERS               = 4.

        ENDLOOP.

      ENDIF.

    ENDIF.

    " Check/register the queue in SMQR
    CALL FUNCTION 'QIWK_CHECK_REGISTER'
      EXPORTING
        qname    = gv_queue_name
      IMPORTING
        register = lv_registration_status.

    IF sy-subrc NE 0 OR lv_registration_status EQ 0.

      CALL FUNCTION 'QIWK_REGISTER'
        STARTING NEW TASK 'QIWK_REGISTER' DESTINATION IN GROUP DEFAULT
        EXPORTING
          qname   = gv_queue_name
          exemode = iv_execution_mode
        EXCEPTIONS
          invalid_queue_name = 1
          invalid_exe_mode   = 2
          OTHERS             = 3.

    ENDIF.

    gv_queue_registered = abap_true.

  ENDMETHOD.


  METHOD get_queue_name.
    rv_queue_name = gv_queue_name.
  ENDMETHOD.


  METHOD set_delay.

    DATA: lv_start_date TYPE sy-datum,
          lv_start_time TYPE tbtcjob-sdlstrttm.

    IF sy-uzeit GE '235900'.
      lv_start_date = sy-datum + 1.
      lv_start_time = sy-uzeit + iv_delay_seconds.
    ELSE.
      lv_start_date = sy-datum.
      lv_start_time = sy-uzeit + iv_delay_seconds.
    ENDIF.

    CALL FUNCTION '/SDF/MON_CALC_QCOUNT'
      EXPORTING
        datum  = lv_start_date
        time   = lv_start_time
      IMPORTING
        qcount = rv_qin_count.

  ENDMETHOD.


  METHOD set_queue.
* DESTINATION 'NONE' means "process in this same system": there is no real
* outbound hop, so the LUW is tagged straight into the INBOUND queue (SMQ2)
* via TRFC_SET_QIN_PROPERTIES, and the QIN scheduler (registered in SMQR)
* decides which free dialog/batch work process picks it up.
* TRFC_SET_QUEUE_NAME (SMQ1/outbound) only matters for calls to a REMOTE
* destination; gv_queue_registered is always TRUE in this class, so that
* branch is kept only for documentation of the original two-queue design.
    IF gv_queue_registered EQ abap_true.
      " Inbound queue (SMQ2)
      CALL FUNCTION 'TRFC_SET_QIN_PROPERTIES'
        EXPORTING
          qin_name  = gv_queue_name
          qin_count = iv_qin_count.
    ELSE.
      " Outbound queue (SMQ1) - dead branch, see note above
      CALL FUNCTION 'TRFC_SET_QUEUE_NAME'
        EXPORTING
          qname = gv_queue_name.
    ENDIF.

  ENDMETHOD.


  METHOD set_queue_name.
    gv_queue_name = iv_queue_name.
  ENDMETHOD.

ENDCLASS.

PARAMETERS:
  p_prefix TYPE name_feld DEFAULT 'YCA_QUEUE_', " Queue-name prefix
  p_qcount TYPE numc2     DEFAULT '01',         " Number of parallel queues to distribute across (01 = single queue, no distribution)
  p_exemod TYPE sy-input  DEFAULT 'D',          " SMQR execution mode: 'D' Dialog / 'B' Batch
  p_total  TYPE i         DEFAULT 20.           " Number of demo items to dispatch through the queue

START-OF-SELECTION.

* Load test: P_TOTAL items are spread across P_QCOUNT named inbound queues
* (SMQ2) instead of spawning P_TOTAL background jobs - each queue processes
* its own items serially, so this throttles concurrency to P_QCOUNT
* in-flight units.
  DATA lv_item_guid TYPE sysuuid_c32.

  DO p_total TIMES.

    DATA(lo_queue_dispatcher) = NEW lcl_queue_dispatcher( iv_queue_prefix   = p_prefix
                                                           iv_queue_count    = p_qcount
                                                           iv_execution_mode = p_exemod ).

    lo_queue_dispatcher->set_queue( ).

    TRY.
        lv_item_guid = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
      CATCH cx_uuid_error.
        CONTINUE.
    ENDTRY.

    CALL FUNCTION 'YCA_QUEUE_WORKER'
      IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT
      EXPORTING
        iv_guid = lv_item_guid.

    COMMIT WORK.

  ENDDO.
