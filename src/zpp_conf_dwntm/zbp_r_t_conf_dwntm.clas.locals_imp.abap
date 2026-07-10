CLASS lhc_zpp_i_conf_dwntm DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR downtime
        RESULT result,
      setdefaultvalues FOR DETERMINE ON MODIFY
        IMPORTING keys FOR downtime~setdefaultvalues,
      updateshift FOR DETERMINE ON MODIFY
        IMPORTING keys FOR downtime~updateshift,
      validatemandatoryfields FOR VALIDATE ON SAVE
        IMPORTING keys FOR downtime~validatemandatoryfields.

ENDCLASS.

CLASS lhc_zpp_i_conf_dwntm IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD setdefaultvalues.

    READ ENTITIES OF zpp_i_conf_dwntm IN LOCAL MODE
       ENTITY downtime
         FIELDS ( downtimeuuid shiftcode groupcode )
         WITH CORRESPONDING #( keys )
       RESULT DATA(lt_header).
    IF lt_header IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ls_header) = VALUE #( lt_header[ 1 ] OPTIONAL ).

    MODIFY ENTITIES OF zpp_i_conf_dwntm IN LOCAL MODE
      ENTITY downtime
        UPDATE FIELDS ( shift )
        WITH VALUE #(
          FOR key IN keys (
            %tky = key-%tky
            shift = |{ ls_header-shiftcode+1(1) }{ ls_header-groupcode }|
          )
        ).

  ENDMETHOD.

  METHOD updateshift.


    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_dwntm.

    READ ENTITIES OF zpp_i_conf_dwntm IN LOCAL MODE
      ENTITY downtime
        FIELDS (
          downtimeuuid
          shiftcode
          groupcode
          shift
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_downtime).

    LOOP AT lt_downtime ASSIGNING FIELD-SYMBOL(<ls_downtime>).

      DATA(lv_new_shift) = CONV zpp_i_conf_dwntm-shift(
        |{ <ls_downtime>-shiftcode+1(1) }{ <ls_downtime>-groupcode }|
      ).

      IF <ls_downtime>-shift = lv_new_shift.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky  = <ls_downtime>-%tky shift = lv_new_shift ) TO lt_update.

    ENDLOOP.

    IF lt_update IS NOT INITIAL.

      MODIFY ENTITIES OF zpp_i_conf_dwntm IN LOCAL MODE
        ENTITY downtime
          UPDATE FIELDS ( shift )
          WITH lt_update
        REPORTED DATA(lt_reported).

    ENDIF.

  ENDMETHOD.

  METHOD validatemandatoryfields.

    READ ENTITIES OF zpp_i_conf_dwntm IN LOCAL MODE
      ENTITY downtime
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_downtime).


    LOOP AT lt_downtime ASSIGNING FIELD-SYMBOL(<lfs_downtime>).

      IF <lfs_downtime>-downtimetext IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-downtimetext = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '060'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF <lfs_downtime>-shiftcode IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-shiftcode = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '061'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF <lfs_downtime>-groupcode IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-groupcode = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '062'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF <lfs_downtime>-material IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-material = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '063'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF <lfs_downtime>-downtimedate IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-downtimedate = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '064'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF <lfs_downtime>-downtimetime IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-downtimetime = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '065'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF <lfs_downtime>-downtimecode IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-downtimecode = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '066'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF <lfs_downtime>-downtimeduration IS INITIAL.
        APPEND VALUE #(
          %tky = <lfs_downtime>-%tky
          %element-downtimeduration = if_abap_behv=>mk-on
          %msg = new_message(
                    id       = zcl_pp_conf=>mc_mess_id
                    number   = '067'
                    severity = if_abap_behv_message=>severity-error ) )
          TO reported-downtime.
      ENDIF.

      IF reported-downtime[] IS NOT INITIAL.
        APPEND VALUE #( %tky = <lfs_downtime>-%tky ) TO failed-downtime.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
