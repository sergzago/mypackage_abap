*&---------------------------------------------------------------------*
*& Include          ZEANDEL_EVENTS
*&---------------------------------------------------------------------*
start-of-selection.
data(go_app) = new lcl_app( ).
go_app->run(
  ir_matnr = s_matnr[] ).
