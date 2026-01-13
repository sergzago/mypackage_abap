*&---------------------------------------------------------------------*
*& Report ZTESTMRC
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZTESTMRC.

CONSTANTS: _mc_kschl_mrc TYPE kschl VALUE 'ZMOC'
             , _mc_atnam_zstrenght TYPE atnam VALUE 'ZSTRENGHT'
             , _mc_kappl_market  TYPE kappl VALUE 'V'                   " NVRDS.EE 08.09.2021 17:14
             , _mc_atnam_zvolume TYPE atnam VALUE 'ZVOLUME'
             , _mc_atnam_tobacco TYPE atnam VALUE 'ZMARK_TYPE'
             , _mc_atwrt_tobacco TYPE atwrt VALUE 'TOBACCO'
             , _mc_so_vkorg TYPE vkorg VALUE 'RU01'
             , _mc_so_vtweg TYPE vtweg VALUE '01'
             .
   DATA: lr_kondm TYPE RANGE OF a934-kondm
         ,_mt_mrc_alco TYPE STANDARD TABLE OF ztlo_mrc
         .
TYPES: BEGIN OF ty_data
         ,   vkorg TYPE a934-vkorg
         ,   vtweg TYPE a934-vtweg
         ,   werks TYPE tvkwz-werks
         ,   matnr TYPE mvke-matnr
         ,   kondm TYPE a934-kondm
         ,   datbi TYPE a934-datbi
         ,   datab TYPE a934-datab
         ,   ksrbm TYPE konm-kstbm
         ,   kbetr TYPE konm-kbetr
         ,   knumh TYPE a934-knumh
         ,   matnr_cristal TYPE mara-zzsetcode
         , END OF ty_data
         , tt_data TYPE STANDARD TABLE OF ty_data.
    DATA: _mt_data TYPE tt_data.
**********************************************************************
   SELECT *
      INTO TABLE _mt_mrc_alco
      FROM ztlo_mrc
     WHERE ztlo_mrc~activ_mrc = abap_true.
    "Алко и табак
    LOOP AT _mt_mrc_alco ASSIGNING FIELD-SYMBOL(<fs_alco>).
      INSERT VALUE #( sign = 'I' option = 'EQ' low = <fs_alco>-kondm ) INTO TABLE lr_kondm.
    ENDLOOP.



SELECT DISTINCT
           a934~vkorg
         , a934~vtweg
         , tvkwz~werks
         , mvke~matnr
         , a934~kondm
         , a934~datbi
         , a934~datab
         , a934~knumh
         , mara~zzsetcode AS matnr_cristal
      INTO CORRESPONDING FIELDS OF TABLE @_mt_data     ##TOO_MANY_ITAB_FIELDS
      FROM a934                                        "#EC CI_BUFFJOIN
*      LEFT JOIN mvke ON mvke~kondm = a934~kondm        " NVRDS.EE 08.09.2021 16:37 Comment
*      LEFT JOIN mara ON mara~matnr = mvke~matnr        " NVRDS.EE 08.09.2021 16:37 Comment
     INNER JOIN mvke ON mvke~vkorg = a934~vkorg         " NVRDS.EE 08.09.2021 16:37
                    AND mvke~vtweg = a934~vtweg         " NVRDS.EE 08.09.2021 16:37
                    AND mvke~kondm = a934~kondm         " NVRDS.EE 08.09.2021 16:37
     INNER JOIN mara ON mara~matnr = mvke~matnr         " NVRDS.EE 08.09.2021 16:37
      LEFT JOIN tvkwz ON tvkwz~vkorg = a934~vkorg
                     AND tvkwz~vtweg = a934~vtweg      "#EC CI_BUFFJOIN
     WHERE a934~kappl  = @_mc_kappl_market              " NVRDS.EE 08.09.2021 16:37
       AND a934~kschl  = @_mc_kschl_mrc
       AND a934~vkorg  = @_mc_so_vkorg
       AND a934~vtweg  = @_mc_so_vtweg
       AND a934~kondm  IN @lr_kondm
       AND a934~datbi  GE @sy-datum "конец срока больше или равен текущей дате
       "AND a934~datbi  GE @_ms_params-date "конец срока больше или равен текущей дате
*       AND a934~datab  LE @ms_params-date "начало срока меньше или равен текущей
       "AND mvke~matnr  IN @_ms_params-so_matnr
       "AND tvkwz~werks IN @_ms_params-so_werks
     ORDER BY a934~vkorg
            , a934~vtweg
            , tvkwz~werks
            , mvke~matnr
            , a934~datbi
            , a934~datab.

WRITE: |Выгружено|.
