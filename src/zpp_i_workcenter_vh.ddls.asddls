@EndUserText.label: 'İş Yeri VH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'WorkCenter'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]
@Search.searchable: true
define view entity ZPP_I_WORKCENTER_VH
  as select from I_WorkCenter as wc
    association [0..1] to I_WorkCenterText as txt
      on  txt.WorkCenterInternalID = wc.WorkCenterInternalID
      and txt.Language             = $session.system_language
{
      @EndUserText.label: 'İş Yeri'
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'WorkCenterText' ]
  key wc.WorkCenter as WorkCenter,

      @EndUserText.label: 'İş Yeri Tanımı'
      @Search.defaultSearchElement: true
      @Semantics.text: true
      txt.WorkCenterText as WorkCenterText
}
where wc.WorkCenterTypeCode = 'A';
