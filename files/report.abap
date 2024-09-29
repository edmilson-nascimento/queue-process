*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT queue.

DATA(go_qrfc) = NEW /yga/cl_qrfc( iv_campo    = '/YGA/QUEUE'
                                  iv_nr_filas = 10 ).

IF go_qrfc IS NOT BOUND.
  RETURN.
ENDIF.

DO 5 TIMES.
  CALL FUNCTION '/YGA/QUEUE'
    IN BACKGROUND TASK DESTINATION 'NONE' AS SEPARATE UNIT
    EXPORTING
      im_time = 7.
ENDDO .

COMMIT WORK.