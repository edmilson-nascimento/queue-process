*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT queue.

DATA(go_qrfc) = NEW /yga/cl_qrfc( iv_campo    = '/YGA/MASS_SITRD'
                                  iv_nr_filas = 10 ).

IF go_qrfc IS NOT BOUND.
  RETURN.
ENDIF.

go_qrfc->set_queue( ).

DO 15 TIMES.
  CALL FUNCTION '/YGA/QUEUE'
    IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT
    EXPORTING
      im_time = 20.
ENDDO .


** despoletar interface ID0021
*  CALL FUNCTION '/YGA/LAUNCH_ADHOC_ID0021' IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT
*    EXPORTING
*      is_viqmel = '' .

COMMIT WORK.