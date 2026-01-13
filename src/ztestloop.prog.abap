*&---------------------------------------------------------------------*
*& Report ZTESTLOOP
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZTESTLOOP.
SELECT *
       FROM spfli
       INTO TABLE @DATA(spfli_tab).

LOOP AT spfli_tab INTO DATA(wa)
                  GROUP BY wa-carrid
                  INTO DATA(key).
  cl_demo_output=>next_section( |{ key }| ).
  DATA(str) = ``.
  LOOP AT GROUP key ASSIGNING FIELD-SYMBOL(<members>).
    str = str && ` ` && <members>-connid.
  ENDLOOP.
  cl_demo_output=>write( str ).
ENDLOOP.
cl_demo_output=>display( ).
