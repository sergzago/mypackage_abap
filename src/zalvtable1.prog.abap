*&---------------------------------------------------------------------*
*& Report ZALVTABLE1
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZALVTABLE1.

CLASS lcl_aligned_salv DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: main.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_data,
             matnr TYPE matnr,
             maktx TYPE maktx,
             menge TYPE menge_d,
             meins TYPE meins,
           END OF ty_data.
    CLASS-DATA: gt_data TYPE TABLE OF ty_data.

    CLASS-METHODS: create_header
      RETURNING VALUE(ro_header) TYPE REF TO cl_salv_form_layout_grid.
ENDCLASS.

CLASS lcl_aligned_salv IMPLEMENTATION.
  METHOD main.
    " Тестовые данные
    gt_data = VALUE #(
      ( matnr = 'MAT001' maktx = 'Материал 1' menge = 100 meins = 'KG' )
      ( matnr = 'MAT002' maktx = 'Материал 2' menge = 200 meins = 'PC' )
      ( matnr = 'MAT003' maktx = 'Материал 3' menge = 150 meins = 'M' )
    ).

    TRY.
*        DATA(lo_salv) = cl_salv_table=>factory( ).
*        lo_salv->set_data( CHANGING t_table = gt_data ).
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = data(lo_salv)
        CHANGING
          t_table      = gt_data ).

         data(lo_functions) = lo_salv->get_functions( ).
         lo_functions->set_all( ).

        " Устанавливаем два заголовка
        lo_salv->set_top_of_list( create_header( ) ).

        " Выравниваем ширину колонок с заголовками
        DATA(lo_columns) = lo_salv->get_columns( ).
        lo_columns->get_column( 'MATNR' )->set_output_length( 20 ).
        lo_columns->get_column( 'MAKTX' )->set_output_length( 30 ).
        lo_columns->get_column( 'MENGE' )->set_output_length( 15 ).
        lo_columns->get_column( 'MEINS' )->set_output_length( 10 ).

        lo_salv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_error).
        MESSAGE lx_error->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD create_header.
    DATA: lo_flow TYPE REF TO cl_salv_form_layout_flow.

    CREATE OBJECT ro_header.

    " Первая строка - описательные названия
    lo_flow = ro_header->create_flow( row = 1 column = 1 ).
    lo_flow->create_text( text = 'Номер материала' ).

    lo_flow = ro_header->create_flow( row = 1 column = 2 ).
    lo_flow->create_text( text = 'Наименование материала' ).

    lo_flow = ro_header->create_flow( row = 1 column = 3 ).
    lo_flow->create_text( text = 'Количество' ).

    lo_flow = ro_header->create_flow( row = 1 column = 4 ).
    lo_flow->create_text( text = 'Ед. измерения' ).

    " Вторая строка - технические имена
    lo_flow = ro_header->create_flow( row = 2 column = 1 ).
    lo_flow->create_text( text = 'MATNR' ).

    lo_flow = ro_header->create_flow( row = 2 column = 2 ).
    lo_flow->create_text( text = 'MAKTX' ).

    lo_flow = ro_header->create_flow( row = 2 column = 3 ).
    lo_flow->create_text( text = 'MENGE' ).

    lo_flow = ro_header->create_flow( row = 2 column = 4 ).
    lo_flow->create_text( text = 'MEINS' ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  lcl_aligned_salv=>main( ).
