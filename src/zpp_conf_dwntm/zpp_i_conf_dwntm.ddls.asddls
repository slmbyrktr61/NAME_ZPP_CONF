@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZPP_CONF_DWNTM'
@EndUserText.label: 'Duruş Verisi Düzenle'
define root view entity ZPP_I_CONF_DWNTM
  as select from zpp_t_conf_dwntm as Downtime

  left outer join I_WorkCenter as WorkCenter
    on WorkCenter.WorkCenter = Downtime.workcenter

  left outer join I_WorkCenterText as WorkCenterText
    on  WorkCenterText.WorkCenterInternalID = WorkCenter.WorkCenterInternalID
    and WorkCenterText.Language             = $session.system_language

  association [0..1] to I_ProductText as _Product
    on  _Product.Product  = Downtime.material
    and _Product.Language = $session.system_language

  association [0..1] to zpp_t_conf_007 as _Reason
    on _Reason.duruskodu = Downtime.downtime_code

{
  key Downtime.downtime_uuid as DowntimeUUID,
      Downtime.shiftcode     as Shiftcode,
      Downtime.groupcode     as Groupcode,

      @ObjectModel.text.element: [ 'WorkCenterText' ]
      Downtime.workcenter    as Workcenter,

      @EndUserText.label: 'İş Yeri Tanımı'
      WorkCenterText.WorkCenterText as WorkCenterText,

      @ObjectModel.text.element: [ 'MaterialDescription' ]
      Downtime.material      as Material,

      @EndUserText.label: 'Malzeme Tanımı'
      _Product.ProductName   as MaterialDescription,

      Downtime.downtime_date     as DowntimeDate,
      Downtime.downtime_time     as DowntimeTime,

      @EndUserText.label: 'Duruş Kodu Tanımı'
      _Reason.durussebebi        as DowntimeCodeDescription,

      Downtime.shift             as Shift,

      @ObjectModel.text.element: [ 'DowntimeCodeDescription' ]
      Downtime.downtime_code     as DowntimeCode,

      Downtime.downtime_duration as DowntimeDuration,

      @UI.multiLineText: true
      Downtime.downtime_text     as DowntimeText,

      @Semantics.user.createdBy: true
      Downtime.created_by        as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      Downtime.created_at        as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      Downtime.last_changed_by   as LastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Downtime.last_changed_at   as LastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      Downtime.local_last_changed_at as LocalLastChangedAt
}
