*&---------------------------------------------------------------------*
*& Report ZMYEANDEL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMYEANDEL.

types: begin of ty_eanmatnr,
    matnr type matnr,
    meinh type meinh,
    ean11 type ean11,
    hpean type hpean,
  end of ty_eanmatnr.

DATA:
      lv_matnr type matnr,
      ls_matnr type ty_eanmatnr,
      lt_matnr type table of ty_eanmatnr.

DATA: lo_alv TYPE REF TO cl_salv_table,
      lo_columns TYPE REF TO cl_salv_columns_table,
      lo_column TYPE REF TO cl_salv_column_table,
      lo_functions TYPE REF TO cl_salv_functions_list,
      lo_sorts type ref to cl_salv_sorts,
      lo_sort type ref to cl_salv_sort.

selection-screen begin of block b1 with frame title text-001.
select-options: s_matnr for lv_matnr.
selection-screen end of block b1.

start-of-selection.

select matnr,
     meinh,
     ean11,
     hpean
  into table @lt_matnr
  from mean
  where matnr in @s_matnr
  order by matnr,meinh,hpean DESCENDING,ean11.

TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_matnr ).

*   Включаем все функции alv-представления
       lo_functions = lo_alv->get_functions( ).
       lo_functions->set_all( ).
*   Сортируем по коду материала
       lo_sorts = lo_alv->get_sorts( ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'MATNR'
          position = 1
          sequence = if_salv_c_sort=>sort_up ).

      " Отображаем ALV-таблицу
      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
      " Обработка ошибок
      MESSAGE lx_salv_msg->get_text( ) TYPE 'E'.
  ENDTRY.
