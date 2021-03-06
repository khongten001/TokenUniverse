unit UI.Information;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus,
  Vcl.ComCtrls, Vcl.Buttons, TU.Tokens, System.ImageList, Vcl.ImgList,
  VclEx.ListView, UI.Prototypes, UI.Prototypes.ChildForm, NtUtils.Security.Sid,
  TU.Tokens.Types, Winapi.WinNt, UI.Prototypes.AuditFrame, UI.Prototypes.Logon,
  UI.Prototypes.Privileges, UI.Prototypes.Groups, NtUtils.Lsa.Audit;

type
  TInfoDialog = class(TChildTaskbarForm)
    PageControl: TPageControl;
    TabGeneral: TTabSheet;
    TabGroups: TTabSheet;
    TabPrivileges: TTabSheet;
    StaticUser: TStaticText;
    EditUser: TEdit;
    ButtonClose: TButton;
    TabRestricted: TTabSheet;
    StaticSession: TStaticText;
    StaticIntegrity: TStaticText;
    ComboSession: TComboBox;
    ComboIntegrity: TComboBox;
    ImageList: TImageList;
    PrivilegePopup: TPopupMenu;
    MenuPrivEnable: TMenuItem;
    MenuPrivDisable: TMenuItem;
    MenuPrivRemove: TMenuItem;
    GroupPopup: TPopupMenu;
    MenuGroupEnable: TMenuItem;
    MenuGroupDisable: TMenuItem;
    MenuGroupReset: TMenuItem;
    TabAdvanced: TTabSheet;
    ListViewAdvanced: TListViewEx;
    StaticOwner: TStaticText;
    ComboOwner: TComboBox;
    ComboPrimary: TComboBox;
    StaticPrimary: TStaticText;
    StaticUIAccess: TStaticText;
    ComboUIAccess: TComboBox;
    StaticText1: TStaticText;
    ListViewGeneral: TListViewEx;
    CheckBoxNoWriteUp: TCheckBox;
    CheckBoxNewProcessMin: TCheckBox;
    StaticVirtualization: TStaticText;
    CheckBoxVAllowed: TCheckBox;
    CheckBoxVEnabled: TCheckBox;
    BtnSetSession: TButton;
    BtnSetIntegrity: TButton;
    BtnSetUIAccess: TButton;
    BtnSetPolicy: TButton;
    BtnSetOwner: TButton;
    BtnSetPrimary: TButton;
    BtnSetVEnabled: TButton;
    BtnSetAEnabled: TButton;
    TabObject: TTabSheet;
    ListViewProcesses: TListViewEx;
    ListViewObject: TListViewEx;
    TabSecurity: TTabSheet;
    TabDefaultDacl: TTabSheet;
    TabAudit: TTabSheet;
    FrameAudit: TFrameAudit;
    TabLogon: TTabSheet;
    FrameLogon: TFrameLogon;
    FramePrivileges: TFramePrivileges;
    FrameGroupSIDs: TFrameGroups;
    FrameRestrictSIDs: TFrameGroups;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure BtnSetIntegrityClick(Sender: TObject);
    procedure BtnSetSessionClick(Sender: TObject);
    procedure DoCloseForm(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SetStaleColor(Sender: TObject);
    procedure ActionPrivilegeEnable(Sender: TObject);
    procedure ActionPrivilegeDisable(Sender: TObject);
    procedure ActionPrivilegeRemove(Sender: TObject);
    procedure ActionGroupEnable(Sender: TObject);
    procedure ActionGroupDisable(Sender: TObject);
    procedure ActionGroupReset(Sender: TObject);
    procedure ListViewGroupsContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure BtnSetUIAccessClick(Sender: TObject);
    procedure BtnSetPolicyClick(Sender: TObject);
    procedure ListViewAdvancedResize(Sender: TObject);
    procedure BtnSetPrimaryClick(Sender: TObject);
    procedure BtnSetOwnerClick(Sender: TObject);
    procedure CheckBoxClick(Sender: TObject);
    procedure BtnSetVEnabledClick(Sender: TObject);
    procedure BtnSetVAllowedClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure ListViewGeneralDblClick(Sender: TObject);
    procedure EditUserDblClick(Sender: TObject);
  private
    Token: TToken;
    SessionSource: TSessionSource;
    IntegritySource: TIntegritySource;
    procedure ChangedCaption(const NewCaption: String);
    procedure ChangedIntegrity(const NewIntegrity: TGroup);
    procedure ChangedSession(const NewSession: Cardinal);
    procedure ChangedUIAccess(const NewUIAccess: LongBool);
    procedure ChangedPolicy(const NewPolicy: Cardinal);
    procedure ChangedPrivileges(const NewPrivileges: TArray<TPrivilege>);
    procedure ChangedGroups(const NewGroups: TArray<TGroup>);
    procedure ChangedStatistics(const NewStatistics: TTokenStatistics);
    procedure ChangedOwner(const NewOwner: ISid);
    procedure ChangedPrimaryGroup(const NewPrimary: ISid);
    procedure ChangedVAllowed(const NewVAllowed: LongBool);
    procedure ChangedVEnabled(const NewVEnabled: LongBool);
    procedure ChangedFlags(const NewFlags: Cardinal);
    procedure SetAuditPolicy(NewAudit: IAudit);
    procedure Refresh;
    procedure UpdateObjectTab;
    procedure UpdateAuditTab;
    procedure UpdateLogonTab;
  public
    constructor CreateFromToken(AOwner: TComponent; SrcToken: TToken);
  end;

implementation

uses
  System.UITypes, UI.MainForm, UI.Colors, UI.ProcessList,
  UI.Information.Access, UI.Sid.View, NtUtils.Processes.Snapshots,
  NtUtils.Objects.Snapshots, DelphiUtils.Strings, NtUtils.Strings,
  Ntapi.ntpsapi, NtUtils.Processes, NtUtils.Access, NtUtils.Exceptions,
  NtUtils.Lsa.Sid, DelphiUtils.Arrays, Ntapi.ntseapi;

const
  TAB_INVALIDATED = 0;
  TAB_UPDATED = 1;

{$R *.dfm}

procedure TInfoDialog.ActionGroupDisable(Sender: TObject);
begin
  if FrameGroupSIDs.ListView.SelCount <> 0 then
    Token.GroupAdjust(FrameGroupSIDs.SelectedGroups, gaDisable);
end;

procedure TInfoDialog.ActionGroupEnable(Sender: TObject);
begin
  if FrameGroupSIDs.ListView.SelCount <> 0 then
    Token.GroupAdjust(FrameGroupSIDs.SelectedGroups, gaEnable);
end;

procedure TInfoDialog.ActionGroupReset(Sender: TObject);
begin
  if FrameGroupSIDs.ListView.SelCount <> 0 then
    Token.GroupAdjust(FrameGroupSIDs.SelectedGroups, gaResetDefault);
end;

procedure TInfoDialog.ActionPrivilegeDisable(Sender: TObject);
begin
  if FramePrivileges.ListView.SelCount <> 0 then
    Token.PrivilegeAdjust(FramePrivileges.SelectedPrivileges, paDisable);
end;

procedure TInfoDialog.ActionPrivilegeEnable(Sender: TObject);
begin
  if FramePrivileges.ListView.SelCount <> 0 then
    Token.PrivilegeAdjust(FramePrivileges.SelectedPrivileges, paEnable);
end;

procedure TInfoDialog.ActionPrivilegeRemove(Sender: TObject);
begin
  if FramePrivileges.ListView.SelCount = 0 then
    Exit;

  if TaskMessageDlg('Remove these privileges from the token?',
    'This action can''t be undone.', mtWarning, mbYesNo, -1) <> idYes then
    Exit;

  Token.PrivilegeAdjust(FramePrivileges.SelectedPrivileges, paRemove);
end;

procedure TInfoDialog.BtnSetIntegrityClick(Sender: TObject);
begin
  try
    Token.InfoClass.IntegrityLevel := IntegritySource.SelectedIntegrity;
    ComboIntegrity.Color := clWindow;
  except
    if Token.InfoClass.Query(tdTokenIntegrity) then
      ChangedIntegrity(Token.InfoClass.Integrity);
    raise;
  end;
end;

procedure TInfoDialog.BtnSetOwnerClick(Sender: TObject);
var
  Sid: ISid;
begin
  try
    LsaxLookupNameOrSddl(ComboOwner.Text, Sid).RaiseOnError;
    Token.InfoClass.Owner := Sid;
    ComboOwner.Color := clWindow;
  except
    if Token.InfoClass.Query(tdTokenOwner) then
      ChangedOwner(Token.InfoClass.Owner);
    raise;
  end;
end;

procedure TInfoDialog.BtnSetPolicyClick(Sender: TObject);
var
  Policy: Cardinal;
begin
  try
    Policy := 0;

    if CheckBoxNoWriteUp.Checked then
      Policy := Policy or TOKEN_MANDATORY_POLICY_NO_WRITE_UP;

    if CheckBoxNewProcessMin.Checked then
      Policy := Policy or TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN;

    Token.InfoClass.MandatoryPolicy := Policy;

    CheckBoxNoWriteUp.Font.Style := [];
    CheckBoxNewProcessMin.Font.Style := [];
  except
    if Token.InfoClass.Query(tdTokenMandatoryPolicy) then
      ChangedPolicy(Token.InfoClass.MandatoryPolicy);
    raise;
  end;
end;

procedure TInfoDialog.BtnSetPrimaryClick(Sender: TObject);
var
  Sid: ISid;
begin
  try
    LsaxLookupNameOrSddl(ComboPrimary.Text, Sid).RaiseOnError;
    Token.InfoClass.PrimaryGroup := Sid;
    ComboPrimary.Color := clWindow;
  except
    if Token.InfoClass.Query(tdTokenPrimaryGroup) then
      ChangedPrimaryGroup(Token.InfoClass.PrimaryGroup);
    raise;
  end;
end;

procedure TInfoDialog.BtnSetSessionClick(Sender: TObject);
begin
  try
    Token.InfoClass.Session := SessionSource.SelectedSession;
  except
    if Token.InfoClass.Query(tdTokenSessionId) then
      ChangedSession(Token.InfoClass.Session);
    raise;
  end;
end;

procedure TInfoDialog.BtnSetUIAccessClick(Sender: TObject);
begin
  try
    if ComboUIAccess.ItemIndex = -1 then
      Token.InfoClass.UIAccess := LongBool(StrToUIntEx(ComboUIAccess.Text,
        'UIAccess value'))
    else
      Token.InfoClass.UIAccess := LongBool(ComboUIAccess.ItemIndex);
    ComboUIAccess.Color := clWindow;
  except
    if Token.InfoClass.Query(tdTokenUIAccess) then
      ChangedUIAccess(Token.InfoClass.UIAccess);
    raise;
  end;
end;

procedure TInfoDialog.BtnSetVAllowedClick(Sender: TObject);
begin
  try
    Token.InfoClass.VirtualizationAllowed := CheckBoxVAllowed.Checked;
    CheckBoxVAllowed.Font.Style := [];
  except
    if Token.InfoClass.Query(tdTokenVirtualizationAllowed) then
      ChangedVAllowed(Token.InfoClass.VirtualizationAllowed);
    raise;
  end;
end;

procedure TInfoDialog.BtnSetVEnabledClick(Sender: TObject);
begin
  try
    Token.InfoClass.VirtualizationEnabled := CheckBoxVEnabled.Checked;
    CheckBoxVEnabled.Font.Style := [];
  except
    if Token.InfoClass.Query(tdTokenVirtualizationEnabled) then
      ChangedVEnabled(Token.InfoClass.VirtualizationEnabled);
    raise;
  end;
end;

procedure TInfoDialog.ChangedCaption(const NewCaption: String);
begin
  Caption := Format('Token Information for "%s"', [NewCaption]);
end;

procedure TInfoDialog.ChangedFlags(const NewFlags: Cardinal);
begin
  ListViewAdvanced.Items[13].SubItems[0] := Token.InfoClass.QueryString(tsFlags);
end;

procedure TInfoDialog.ChangedGroups(const NewGroups: TArray<TGroup>);
var
  i: Integer;
begin
  TabGroups.Caption := Format('Groups (%d)', [Length(NewGroups)]);

  // Update group list
  with FrameGroupSIDs do
  begin
    ListView.Items.BeginUpdate(True);

    Clear;
    AddGroups(NewGroups);

    ListView.Items.EndUpdate(True);
  end;

  // Update suggestions for Owner and Primary Group
  ComboOwner.Items.BeginUpdate;
  ComboPrimary.Items.BeginUpdate;

  ComboOwner.Items.Clear;
  ComboPrimary.Items.Clear;

  // Add User since it is always assignable
  if Token.InfoClass.Query(tdTokenUser) then
  begin
    ComboOwner.Items.Add(LsaxSidToString(
      Token.InfoClass.User.SecurityIdentifier.Sid));
    ComboPrimary.Items.Add(LsaxSidToString(
      Token.InfoClass.User.SecurityIdentifier.Sid));
  end;

  // Add all groups for Primary Group and only those with specific attribtes
  // for Owner.
  for i := 0 to High(NewGroups) do
  begin
    ComboPrimary.Items.Add(LsaxSidToString(
      NewGroups[i].SecurityIdentifier.Sid));
    if Contains(NewGroups[i].Attributes, SE_GROUP_OWNER) then
      ComboOwner.Items.Add(LsaxSidToString(
        NewGroups[i].SecurityIdentifier.Sid));
  end;

  ComboPrimary.Items.EndUpdate;
  ComboOwner.Items.EndUpdate;
end;

procedure TInfoDialog.ChangedIntegrity(const NewIntegrity: TGroup);
begin
  ComboIntegrity.Color := clWindow;
  IntegritySource.SelectedIntegrity := NewIntegrity.SecurityIdentifier.Rid;
  ComboIntegrity.Hint := BuildSidHint(NewIntegrity.SecurityIdentifier,
    NewIntegrity.Attributes);
end;

procedure TInfoDialog.ChangedOwner(const NewOwner: ISid);
begin
  ComboOwner.Color := clWindow;
  ComboOwner.Text := LsaxSidToString(NewOwner.Sid);
end;

procedure TInfoDialog.ChangedPolicy(const NewPolicy: Cardinal);
begin
  CheckBoxNoWriteUp.Checked := Contains(NewPolicy,
    TOKEN_MANDATORY_POLICY_NO_WRITE_UP);

  CheckBoxNewProcessMin.Checked := Contains(NewPolicy,
    TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN);

  CheckBoxNoWriteUp.Font.Style := [];
  CheckBoxNewProcessMin.Font.Style := [];
end;

procedure TInfoDialog.ChangedPrimaryGroup(const NewPrimary: ISid);
begin
  ComboPrimary.Color := clWindow;
  ComboPrimary.Text := LsaxSidToString(NewPrimary.Sid);
end;

procedure TInfoDialog.ChangedPrivileges(const NewPrivileges: TArray<TPrivilege>);
begin
  TabPrivileges.Caption := Format('Privileges (%d)', [Length(NewPrivileges)]);

  FramePrivileges.ListView.Items.BeginUpdate(True);

  FramePrivileges.Clear;
  FramePrivileges.AddPrivileges(NewPrivileges);

  FramePrivileges.ListView.Items.EndUpdate(True);
end;

procedure TInfoDialog.ChangedSession(const NewSession: Cardinal);
begin
  ComboSession.Color := clWindow;
  SessionSource.SelectedSession := NewSession;
end;

procedure TInfoDialog.ChangedStatistics(const NewStatistics: TTokenStatistics);
begin
  with ListViewAdvanced do
  begin
    Items[2].SubItems[0] := Token.InfoClass.QueryString(tsTokenID);
    Items[3].SubItems[0] := Token.InfoClass.QueryString(tsLogonID);
    Items[4].SubItems[0] := Token.InfoClass.QueryString(tsExprires);
    Items[5].SubItems[0] := Token.InfoClass.QueryString(tsDynamicCharged);
    Items[6].SubItems[0] := Token.InfoClass.QueryString(tsDynamicAvailable);
    Items[7].SubItems[0] := Token.InfoClass.QueryString(tsGroupCount);
    Items[8].SubItems[0] := Token.InfoClass.QueryString(tsPrivilegeCount);
    Items[9].SubItems[0] := Token.InfoClass.QueryString(tsModifiedID);
    // TODO: Error hints
  end;
end;

procedure TInfoDialog.ChangedUIAccess(const NewUIAccess: LongBool);
begin
  ComboUIAccess.Color := clWhite;
  ComboUIAccess.ItemIndex := Integer(NewUIAccess = True);
end;

procedure TInfoDialog.ChangedVAllowed(const NewVAllowed: LongBool);
begin
  CheckBoxVAllowed.OnClick := nil;
  CheckBoxVAllowed.Font.Style := [];
  CheckBoxVAllowed.Checked := NewVAllowed;
  CheckBoxVAllowed.OnClick := CheckBoxClick;
end;

procedure TInfoDialog.ChangedVEnabled(const NewVEnabled: LongBool);
begin
  CheckBoxVEnabled.OnClick := nil;
  CheckBoxVEnabled.Font.Style := [];
  CheckBoxVEnabled.Checked := NewVEnabled;
  CheckBoxVEnabled.OnClick := CheckBoxClick;
end;

procedure TInfoDialog.CheckBoxClick(Sender: TObject);
begin
  Assert(Sender is TCheckBox);
  (Sender as TCheckBox).Font.Style := [fsBold];
end;

constructor TInfoDialog.CreateFromToken(AOwner: TComponent; SrcToken: TToken);
begin
  Assert(Assigned(SrcToken));
  Token := SrcToken;
  inherited Create(AOwner);
  Show;
end;

procedure TInfoDialog.DoCloseForm(Sender: TObject);
begin
  Close;
end;

procedure TInfoDialog.EditUserDblClick(Sender: TObject);
begin
  if Token.InfoClass.Query(tdTokenUser) then
    TDialogSidView.CreateView(Token.InfoClass.User.SecurityIdentifier);
end;

procedure TInfoDialog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Token.Events.OnFlagsChange.Unsubscribe(ChangedFlags);
  Token.Events.OnVirtualizationEnabledChange.Unsubscribe(ChangedVEnabled);
  Token.Events.OnVirtualizationAllowedChange.Unsubscribe(ChangedVAllowed);
  Token.Events.OnPrimaryChange.Unsubscribe(ChangedPrimaryGroup);
  Token.Events.OnOwnerChange.Unsubscribe(ChangedOwner);
  Token.Events.OnStatisticsChange.Unsubscribe(ChangedStatistics);
  Token.Events.OnGroupsChange.Unsubscribe(ChangedGroups);
  Token.Events.OnPrivilegesChange.Unsubscribe(ChangedPrivileges);
  Token.Events.OnPolicyChange.Unsubscribe(ChangedPolicy);
  Token.Events.OnIntegrityChange.Unsubscribe(ChangedIntegrity);
  Token.Events.OnUIAccessChange.Unsubscribe(ChangedUIAccess);
  Token.Events.OnSessionChange.Unsubscribe(ChangedSession);
  Token.OnCaptionChange.Unsubscribe(ChangedCaption);
  IntegritySource.Free;
  SessionSource.Free;
  UnsubscribeTokenCanClose(Token);
end;

procedure TInfoDialog.FormCreate(Sender: TObject);
begin
  SubscribeTokenCanClose(Token, Caption);
  SessionSource := TSessionSource.Create(ComboSession, False);
  IntegritySource := TIntegritySource.Create(ComboIntegrity);
  FrameAudit.OnApplyClick := SetAuditPolicy;

  // "Refresh" queries all the information, stores changeble one in the event
  // handler, and distributes changed one to every existing event listener
  Refresh;

  // Than subscribtion calls our event listeners with the latest availible
  // information that is stored in the event handlers. By doing that in this
  // order we avoid multiple calls while sharing the data between different
  // tokens pointing the same kernel object.
  Token.Events.OnSessionChange.Subscribe(ChangedSession);
  Token.Events.OnUIAccessChange.Subscribe(ChangedUIAccess);
  Token.Events.OnIntegrityChange.Subscribe(ChangedIntegrity);
  Token.Events.OnPolicyChange.Subscribe(ChangedPolicy);
  Token.Events.OnPrivilegesChange.Subscribe(ChangedPrivileges);
  Token.Events.OnGroupsChange.Subscribe(ChangedGroups);
  Token.Events.OnStatisticsChange.Subscribe(ChangedStatistics);
  Token.Events.OnOwnerChange.Subscribe(ChangedOwner);
  Token.Events.OnPrimaryChange.Subscribe(ChangedPrimaryGroup);
  Token.Events.OnVirtualizationAllowedChange.Subscribe(ChangedVAllowed);
  Token.Events.OnVirtualizationEnabledChange.Subscribe(ChangedVEnabled);
  Token.Events.OnFlagsChange.Subscribe(ChangedFlags);

  Token.OnCaptionChange.Subscribe(ChangedCaption);
  Token.OnCaptionChange.Invoke(Token.Caption);

  TabRestricted.Caption := Format('Restricting SIDs (%d)',
    [FrameRestrictSIDs.ListView.Items.Count]);
end;

procedure TInfoDialog.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F5 then
    Refresh;
end;

procedure TInfoDialog.ListViewAdvancedResize(Sender: TObject);
begin
  // HACK: designs-time AutoSize causes horizontal scrollbar to appear
  ListViewAdvanced.Columns[1].AutoSize := True;
end;

procedure TInfoDialog.ListViewGeneralDblClick(Sender: TObject);
begin
  if Assigned(ListViewGeneral.Selected) and
    (ListViewGeneral.Selected.Index = 2) and Token.InfoClass.Query(tdObjectInfo)
    then
    TDialogGrantedAccess.Execute(Self,
      Token.InfoClass.ObjectInformation.GrantedAccess);
end;

procedure TInfoDialog.ListViewGroupsContextPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
begin
  MenuGroupEnable.Visible := FrameGroupSIDs.ListView.SelCount <> 0;
  MenuGroupDisable.Visible := FrameGroupSIDs.ListView.SelCount <> 0;
end;

procedure TInfoDialog.PageControlChange(Sender: TObject);
begin
  if PageControl.ActivePageIndex = TabObject.TabIndex then
    UpdateObjectTab
  else if PageControl.ActivePageIndex = TabAudit.TabIndex then
    UpdateAuditTab
  else if PageControl.ActivePageIndex = TabLogon.TabIndex then
    UpdateLogonTab;
end;

procedure TInfoDialog.Refresh;
begin
  ListViewGeneral.Items.BeginUpdate;
  with ListViewGeneral do
  begin
    Items[0].SubItems[0] := Token.InfoClass.QueryString(tsObjectAddress);
    ListViewObject.Items[0].SubItems[0] := Items[0].SubItems[0];
    Items[1].SubItems[0] := Token.InfoClass.QueryString(tsHandle);
    Items[2].SubItems[0] := Token.InfoClass.QueryString(tsAccess, True);
    Items[3].SubItems[0] := Token.InfoClass.QueryString(tsTokenType);
    Items[4].SubItems[0] := Token.InfoClass.QueryString(tsElevation);
  end;
  ListViewGeneral.Items.EndUpdate;

  ListViewAdvanced.Items.BeginUpdate;
  with ListViewAdvanced do
  begin
    Items[0].SubItems[0] := Token.InfoClass.QueryString(tsSourceName);
    Items[1].SubItems[0] := Token.InfoClass.QueryString(tsSourceLUID);
    Items[10].SubItems[0] := Token.InfoClass.QueryString(tsSandboxInert);
    Items[11].SubItems[0] := Token.InfoClass.QueryString(tsHasRestrictions);
    Items[12].SubItems[0] := Token.InfoClass.QueryString(tsIsRestricted);
  end;
  ListViewAdvanced.Items.EndUpdate;

  // This triggers events if the value has changed
  Token.InfoClass.ReQuery(tdTokenIntegrity);
  Token.InfoClass.ReQuery(tdTokenSessionId);
  Token.InfoClass.ReQuery(tdTokenOrigin);
  Token.InfoClass.ReQuery(tdTokenUIAccess);
  Token.InfoClass.ReQuery(tdTokenMandatoryPolicy);
  Token.InfoClass.ReQuery(tdTokenPrivileges);
  Token.InfoClass.ReQuery(tdTokenGroups);
  Token.InfoClass.ReQuery(tdTokenStatistics);
  Token.InfoClass.ReQuery(tdTokenOwner);
  Token.InfoClass.ReQuery(tdTokenPrimaryGroup);
  Token.InfoClass.ReQuery(tdTokenVirtualizationAllowed);
  Token.InfoClass.ReQuery(tdTokenVirtualizationEnabled);
  Token.InfoClass.ReQuery(tdTokenFlags);

  if Token.InfoClass.Query(tdTokenUser) then
    with Token.InfoClass.User, EditUser do
    begin
      Text := LsaxSidToString(SecurityIdentifier.Sid);
      Hint := BuildSidHint(SecurityIdentifier, Attributes);

      if Contains(Attributes, SE_GROUP_USE_FOR_DENY_ONLY) then
        Color := clDisabled
      else
        Color := clEnabled;
    end;

  if Token.InfoClass.Query(tdTokenRestrictedSids) then
    with FrameRestrictSIDs do
    begin
      ListView.Items.BeginUpdate;
      Clear;
      AddGroups(Token.InfoClass.RestrictedSids);
      ListView.Items.EndUpdate;
    end;

  TabObject.Tag := TAB_INVALIDATED;
  TabAudit.Tag := TAB_INVALIDATED;
  PageControlChange(Self);
end;

procedure TInfoDialog.SetAuditPolicy(NewAudit: IAudit);
begin
  try
    Token.InfoClass.AuditPolicy := NewAudit as IPerUserAudit;
  finally
    TabAudit.Tag := TAB_INVALIDATED;
    UpdateAuditTab;
  end;
end;

procedure TInfoDialog.SetStaleColor(Sender: TObject);
begin
  Assert(Sender is TComboBox);
  (Sender as TComboBox).Color := clStale;
end;

procedure TInfoDialog.UpdateAuditTab;
begin
  if TabAudit.Tag = TAB_UPDATED then
    Exit;

  // TODO: Subscribe event
  if Token.InfoClass.ReQuery(tdTokenAuditPolicy) then
    FrameAudit.Load(Token.InfoClass.AuditPolicy)
  else
    FrameAudit.Load(nil);

  TabAudit.Tag := TAB_UPDATED;
end;

procedure TInfoDialog.UpdateLogonTab;
begin
  if TabLogon.Tag = TAB_UPDATED then
    Exit;

  Token.InfoClass.ReQuery(tdTokenStatistics);
  Token.InfoClass.ReQuery(tdTokenOrigin);

  if not FrameLogon.Subscribed then
    FrameLogon.SubscribeToken(Token);

  TabLogon.Tag := TAB_UPDATED;
end;

procedure TInfoDialog.UpdateObjectTab;
var
  Handles: TArray<TSystemHandleEntry>;
  OpenedSomewhereElse: Boolean;
  Processes: TArray<TProcessEntry>;
  Process: PProcessEntry;
  ProcessesSnapshotted: Boolean;
  ObjTypes: TArray<TObjectTypeEntry>;
  ObjEntry: PObjectEntry;
  CreatorImageName: String;
  i: Integer;
begin
  if TabObject.Tag = TAB_UPDATED then
    Exit;

  ProcessesSnapshotted := False;

  // Update basic object information
  if Token.InfoClass.ReQuery(tdObjectInfo) then
    with ListViewObject, Token.InfoClass.ObjectInformation do
    begin
      Items[1].SubItems[0] := MapFlags(Attributes, ObjAttributesFlags, 'None');
      Items[2].SubItems[0] := BytesToString(PagedPoolCharge);
      Items[3].SubItems[0] := BytesToString(NonPagedPoolCharge);
      Items[4].SubItems[0] := IntToStr(PointerCount);
      Items[5].SubItems[0] := IntToStr(HandleCount);
    end;

  ListViewProcesses.Items.BeginUpdate;
  ListViewProcesses.Items.Clear;
  ListViewProcesses.SmallImages := TProcessIcons.ImageList;

  if not Token.InfoClass.Query(tdHandleInfo) then
    Exit;

  // Snapshot handles and find the ones pointing to that object
  if NtxEnumerateHandles(Handles).IsSuccess then
  begin
    TArrayHelper.Filter<TSystemHandleEntry>(Handles, FilterByAddress,
      NativeUInt(Token.InfoClass.HandleInformation.PObject));

    OpenedSomewhereElse := False;

    // Add handle from current process and check if there are any other
    for i := 0 to High(Handles) do
      if Handles[i].UniqueProcessId = NtCurrentProcessId then
        with ListViewProcesses.Items.Add do
        begin
          Caption := 'Current process';
          SubItems.Add(IntToStr(NtCurrentProcessId));
          SubItems.Add(IntToHexEx(Handles[i].HandleValue));
          SubItems.Add(FormatAccess(Handles[i].GrantedAccess, @TokenAccessType));
          ImageIndex := TProcessIcons.GetIcon(ParamStr(0));
        end
      else
        OpenedSomewhereElse := True;

    // Add handles from other processes
    if OpenedSomewhereElse then
    begin
      if not NtxEnumerateProcesses(Processes).IsSuccess then
        SetLength(Processes, 0);

      ProcessesSnapshotted := True;

      for i := 0 to High(Handles) do
      if (Handles[i].UniqueProcessId <> NtCurrentProcessId) then
        with ListViewProcesses.Items.Add do
        begin
          Process := NtxFindProcessById(Processes, Handles[i].UniqueProcessId);

          if Assigned(Process) then
            Caption := Process.Process.GetImageName
          else
            Caption := 'Unknown process';

          SubItems.Add(IntToStr(Handles[i].UniqueProcessId));
          SubItems.Add(IntToHexEx(Handles[i].HandleValue));
          SubItems.Add(FormatAccess(Handles[i].GrantedAccess, @TokenAccessType));
          ImageIndex := TProcessIcons.GetIcon(
            NtxTryQueryImageProcessById(Handles[i].UniqueProcessId));
        end;
    end;
  end;

  // Obtain object creator by snapshotting objects on the system
  with ListViewObject.Items[6] do
    if NtxObjectEnumerationSupported then
    begin
      if NtxEnumerateObjects(ObjTypes).IsSuccess then
      begin
        ObjEntry := NtxFindObjectByAddress(ObjTypes,
          Token.InfoClass.HandleInformation.PObject);

        if Assigned(ObjEntry) then
        begin
          if ObjEntry.Other.CreatorUniqueProcess = NtCurrentProcessId then
             CreatorImageName := 'Current process'
          else
          begin
            // The creator is somone else, we need to snapshot processes
            // if it's not done already.
            if not ProcessesSnapshotted then
              if not NtxEnumerateProcesses(Processes).IsSuccess then
                SetLength(Processes, 0);

            Process := NtxFindProcessById(Processes,
              ObjEntry.Other.CreatorUniqueProcess);

            if Assigned(Process) then
            begin
              Hint := 'Since process IDs might be reused, ' +
                      'image name might be incorrect';
              CreatorImageName := Process.Process.GetImageName;
            end
            else // Use default unknown name
              CreatorImageName := 'Unknown process';
          end;

          SubItems[0] := Format('PID %d (%s)', [
            ObjEntry.Other.CreatorUniqueProcess, CreatorImageName]);
        end
        else
          SubItems[0] := 'Kernel';
      end
      else
        SubItems[0] := 'Unknown';
    end
    else
      Hint := 'Enable global flag FLG_MAINTAIN_OBJECT_TYPELIST (0x4000).';

  ListViewProcesses.Items.EndUpdate;
  TabObject.Tag := TAB_UPDATED;
end;

end.
