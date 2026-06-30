CLASS zpp_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZPP_UTIL IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

*    DATA(lr_conf) = NEW zcl_pp_conf(  ).
*
*    DATA: lv_material TYPE matnr VALUE '000000000003000215'.
*    DATA: lv_billofmaterial TYPE char8 VALUE '00000021'.
*
*    lv_material = |{ '000000000003000215' }|.
*    lv_billofmaterial  = |{ '00000021' }|.
*
*    DATA(lt_results) = lr_conf->explode_bom(
*                        iv_material = lv_material ).


*    DELETE FROM zpp_t_conf_h.
*    DELETE FROM zpp_t_conf_h_d.
*    DELETE FROM zpp_t_conf_i.
*    DELETE FROM zpp_t_conf_i_d.
*    DELETE FROM zpp_t_conf_log.
    DELETE FROM zpp_t_conf_dwntm.

*    DATA: ls_addmat TYPE zpp_t_addmat.
*    ls_addmat = VALUE #( product = 'IC900300' additional_product = 'IIC900301' ).
*    MODIFY zpp_t_addmat FROM @ls_addmat.


  ENDMETHOD.
ENDCLASS.
