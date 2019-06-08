{
Copyright (C) Alexey Torgashin, uvviewsoft.com
License: MPL 2.0 or LGPL
}

unit ATButtons;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Menus,
  Types, Math, Forms, ExtCtrls,
  ATFlatThemes,
  FPTimer,
  LCLType;

type
  TATButtonKind = (
    abuTextOnly,
    abuIconOnly,
    abuTextIconHorz,
    abuTextIconVert,
    abuSeparatorHorz,
    abuSeparatorVert,
    abuTextChoice
    );

const
  cATButtonKindValues: array[TATButtonKind] of string = (
    'text',
    'icon',
    'text_icon_h',
    'text_icon_v',
    'sep_h',
    'sep_v',
    'text_choice'
    );

const
  cDefaultButtonPadding = 4;
  cDefaultButtonPaddingBig = 5;

type
  { TATButton }

  TATButton = class(TCustomControl)
  private
    FPressed: boolean;
    FOver: boolean;
    FChecked: boolean;
    FCheckable: boolean;
    FFocusable: boolean;
    FPicture: TPicture;
    FImages: TImageList;
    FImageIndex: integer;
    FArrow: boolean;
    FArrowAlign: TAlignment;
    FFlat: boolean;
    FKind: TATButtonKind;
    FBoldBorder: boolean;
    FBoldFont: boolean;
    FDataString: string;
    FDataString2: string;
    FDataString3: string;
    FItems: TStringList;
    FItemIndex: integer;
    FPopup: TPopupMenu;
    FPadding: integer;
    FPaddingBig: integer;
    FTheme: PATFlatTheme;
    FTimerMouseover: TFPTimer;
    FWidthInitial: integer;
    FTextOverlay: string;
    procedure DoChoiceClick(Sender: TObject);
    function GetIconHeight: integer;
    function GetIconWidth: integer;
    function IsPressed: boolean;
    procedure PaintBorder(C: TCanvas; R: TRect; AColor: TColor; AWidth: integer);
    procedure PaintIcon(AX, AY: integer);
    procedure PaintArrow(AX, AY: integer);
    procedure SetBoldFont(AValue: boolean);
    procedure SetChecked(AValue: boolean);
    procedure SetFlat(AValue: boolean);
    procedure SetFocusable(AValue: boolean);
    procedure SetImageIndex(AValue: integer);
    procedure SetImages(AValue: TImageList);
    procedure SetKind(AValue: TATButtonKind);
    procedure SetBoldBorder(AValue: boolean);
    procedure SetTextOverlay(const AValue: string);
    procedure SetTheme(AValue: PATFlatTheme);
    procedure ShowChoiceMenu;
    procedure TimerMouseoverTick(Sender: TObject);
  protected
    procedure Click; override;
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseEnter; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyPress(var Key: char); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure TextChanged; override;
    procedure Resize; override;
    procedure SetAutoSize(AValue: boolean); override;
    function DoScale(AValue: integer): integer;
    function DoScaleFont(AValue: integer): integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanFocus: boolean; override;
    property DataString: string read FDataString write FDataString;
    property DataString2: string read FDataString2 write FDataString2;
    property DataString3: string read FDataString3 write FDataString3;
    function GetTextSize(C: TCanvas; const S: string): TSize;
    property Items: TStringList read FItems;
    property ItemIndex: integer read FItemIndex write FItemIndex;
    property Theme: PATFlatTheme read FTheme write SetTheme;
    property WidthInitial: integer read FWidthInitial write FWidthInitial;
    property TextOverlay: string read FTextOverlay write SetTextOverlay;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property TabStop;
    property TabOrder;
    property Enabled;
    property Visible;
    property ShowHint;
    property ParentShowHint;
    property PopupMenu;
    property Checked: boolean read FChecked write SetChecked default false;
    property Checkable: boolean read FCheckable write FCheckable default false;
    property Images: TImageList read FImages write SetImages;
    property ImageIndex: integer read FImageIndex write SetImageIndex default -1;
    property Focusable: boolean read FFocusable write SetFocusable default true;
    property Flat: boolean read FFlat write SetFlat default false;
    property Arrow: boolean read FArrow write FArrow default false;
    property ArrowAlign: TAlignment read FArrowAlign write FArrowAlign default taRightJustify;
    property Kind: TATButtonKind read FKind write SetKind default abuTextOnly;
    property BoldBorder: boolean read FBoldBorder write SetBoldBorder default false;
    property BoldFont: boolean read FBoldFont write SetBoldFont default false;
    property Picture: TPicture read FPicture write FPicture;
    property Padding: integer read FPadding write FPadding default cDefaultButtonPadding;
    property PaddingBig: integer read FPaddingBig write FPaddingBig default cDefaultButtonPaddingBig;
    property OnClick;
    property OnDblClick;
    property OnResize;
    property OnContextPopup;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
  end;

implementation

procedure CanvasPaintTriangleDown(C: TCanvas; AColor: TColor; ACoord: TPoint; ASize: integer);
begin
  C.Brush.Color:= ColorToRGB(AColor);
  C.Pen.Color:= ColorToRGB(AColor);
  C.Polygon([
    Point(ACoord.X - ASize*2, ACoord.Y - ASize),
    Point(ACoord.X + ASize*2, ACoord.Y - ASize),
    Point(ACoord.X, ACoord.Y + ASize)
    ]);
end;

{ TATButton }

procedure TATButton.SetChecked(AValue: boolean);
begin
  if FChecked=AValue then Exit;
  FChecked:= AValue;
  Invalidate;
end;

procedure TATButton.SetFlat(AValue: boolean);
begin
  if FFlat=AValue then Exit;
  FFlat:= AValue;
  Invalidate;
  if FFlat then
    Focusable:= false;
end;

procedure TATButton.SetFocusable(AValue: boolean);
begin
  if FFocusable=AValue then Exit;
  FFocusable:= AValue;
  TabStop:= AValue;
end;

procedure TATButton.SetImageIndex(AValue: integer);
begin
  if FImageIndex=AValue then Exit;
  FImageIndex:= AValue;
  Invalidate;
end;

procedure TATButton.SetImages(AValue: TImageList);
begin
  if FImages=AValue then Exit;
  FImages:= AValue;
  Invalidate;
end;

procedure TATButton.SetKind(AValue: TATButtonKind);
begin
  if FKind=AValue then Exit;
  FKind:= AValue;
  Invalidate;
end;

procedure TATButton.SetBoldBorder(AValue: boolean);
begin
  if FBoldBorder=AValue then Exit;
  FBoldBorder:= AValue;
  Invalidate;
end;

procedure TATButton.SetTextOverlay(const AValue: string);
begin
  if FTextOverlay=AValue then Exit;
  FTextOverlay:= AValue;
  Invalidate;
end;

procedure TATButton.SetTheme(AValue: PATFlatTheme);
begin
  if FTheme=AValue then Exit;
  FTheme:= AValue;
  Invalidate;
end;

procedure TATButton.Click;
begin
  if FKind=abuTextChoice then
  begin
    ShowChoiceMenu;
    exit
  end;

  inherited;
  if FCheckable then
    FChecked:= not FChecked;
  Invalidate;
end;

function TATButton.CanFocus: boolean;
begin
  Result:= FFocusable;
end;

function TATButton.IsPressed: boolean;
begin
  Result:= FPressed and FOver;
end;

procedure TATButton.PaintBorder(C: TCanvas; R: TRect; AColor: TColor; AWidth: integer);
var
  i: integer;
begin
  C.Brush.Style:= bsClear;
  C.Pen.Color:= ColorToRGB(AColor);
  C.Rectangle(R);

  for i:= 1 to AWidth-1 do
  begin
    InflateRect(R, -1, -1);
    C.Rectangle(R);
  end;

  C.Brush.Style:= bsSolid;
end;

procedure TATButton.Paint;
var
  r: TRect;
  pnt1, pnt2: TPoint;
  NSize, dy, NSizeArrow: integer;
  bUseBack, bUseBorder: boolean;
  NColor: TColor;
  TextSize: TSize;
  S: string;
begin
  inherited;

  if FArrow then
    NSizeArrow:= DoScale(4*Theme^.ArrowSize)
  else
    NSizeArrow:= 0;

  bUseBack:=
    (not FFlat)
    or FChecked
    or (FOver and not (FKind in [abuSeparatorHorz, abuSeparatorVert]));
  bUseBorder:= bUseBack
    or (FKind=abuTextChoice);

  r:= ClientRect;

  if bUseBack then
  begin
    if not Enabled then
      NColor:= Theme^.ColorBgDisabled
    else
    if FChecked then
      NColor:= Theme^.ColorBgChecked
    else
    if FOver then
      NColor:= Theme^.ColorBgOver
    else
      NColor:= Theme^.ColorBgPassive;
    Canvas.Brush.Color:= ColorToRGB(NColor);
    Canvas.FillRect(r);
  end;

  if bUseBorder then
  begin
    if FOver then
      NColor:= Theme^.ColorBorderOver
    else
    if Focused then
      NColor:= Theme^.ColorBorderFocused
    else
      NColor:= Theme^.ColorBorderPassive;

    NSize:= 1;
    if IsPressed then
      NSize:= Theme^.PressedBorderWidth
    else
    if BoldBorder then
      NSize:= Theme^.BoldBorderWidth
    else
    if Kind=abuTextChoice then
      NSize:= Theme^.ChoiceBorderWidth
    else
    if FOver then
      NSize:= Theme^.MouseoverBorderWidth;

    PaintBorder(Canvas, R, NColor, NSize);
  end;

  Canvas.Font.Name:= Theme^.FontName;
  Canvas.Font.Color:= ColorToRGB(IfThen(Enabled, Theme^.ColorFont, Theme^.ColorFontDisabled));
  Canvas.Font.Size:= DoScaleFont(Theme^.FontSize);

  if BoldFont then
    Canvas.Font.Style:= [fsBold]
  else
    Canvas.Font.Style:= Theme^.FontStyles;
  Canvas.Brush.Style:= bsClear;

  case FKind of
    abuIconOnly:
      begin
        pnt1.x:= (ClientWidth-GetIconWidth) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftX) -
          IfThen(Arrow, Padding);
        pnt1.y:= (ClientHeight-GetIconHeight) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftY);
        PaintIcon(pnt1.x, pnt1.y);
      end;

    abuTextOnly:
      begin
        TextSize:= GetTextSize(Canvas, Caption);
        pnt1.x:= (ClientWidth-TextSize.cx-NSizeArrow) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftX);
        pnt1.y:= (ClientHeight-TextSize.cy) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftY);
        Canvas.TextOut(pnt1.x, pnt1.y, Caption);
      end;

    abuTextIconHorz:
      begin
        TextSize:= GetTextSize(Canvas, Caption);
        pnt1.x:= FPadding +
          IfThen(IsPressed, Theme^.PressedCaptionShiftX);
        pnt1.y:= (ClientHeight-GetIconHeight) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftY);
        PaintIcon(pnt1.x, pnt1.y);

        Inc(pnt1.x, GetIconWidth+FPadding);
        pnt1.y:= (ClientHeight-TextSize.cy) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftY);
        Canvas.TextOut(pnt1.x, pnt1.y, Caption);
      end;

    abuTextIconVert:
      begin
        TextSize:= GetTextSize(Canvas, Caption);
        pnt1.x:= (ClientWidth-GetIconWidth-NSizeArrow) div 2+
          IfThen(IsPressed, Theme^.PressedCaptionShiftX);
        pnt1.y:= FPadding +
          IfThen(IsPressed, Theme^.PressedCaptionShiftY);
        PaintIcon(pnt1.x, pnt1.y);

        Inc(pnt1.y, GetIconHeight+FPadding);
        pnt1.x:= (ClientWidth-TextSize.cx-NSizeArrow) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftX);
        Canvas.TextOut(pnt1.x, pnt1.y, Caption);
      end;

    abuTextChoice:
      begin
        pnt1.x:= FPadding +
          IfThen(FArrowAlign=taLeftJustify, FPadding + NSizeArrow) +
          IfThen(IsPressed, Theme^.PressedCaptionShiftX);
        pnt1.y:= (ClientHeight-GetTextSize(Canvas, 'W').cy) div 2 +
          IfThen(IsPressed, Theme^.PressedCaptionShiftY);
        if (FItemIndex>=0) and (FItemIndex<FItems.Count) then
          S:= FItems[FItemIndex]
        else
          S:= '?';
        Canvas.TextOut(pnt1.x, pnt1.y, S);
      end;

    abuSeparatorVert:
      begin
        dy:= 2;
        pnt1:= Point(dy, Height div 2);
        pnt2:= Point(Width-dy, Height div 2);
        Canvas.Pen.Color:= ColorToRGB(Theme^.ColorSeparators);
        Canvas.Line(pnt1, pnt2);
      end;

    abuSeparatorHorz:
      begin
        dy:= 2;
        pnt1:= Point(Width div 2, dy);
        pnt2:= Point(Width div 2, Height-dy);
        Canvas.Pen.Color:= ColorToRGB(Theme^.ColorSeparators);
        Canvas.Line(pnt1, pnt2);
      end;
  end;

  if FArrow then
  begin
    case FArrowAlign of
      taLeftJustify:
        pnt1.x:= NSizeArrow;
      taRightJustify:
        pnt1.x:= ClientWidth - NSizeArrow;
      taCenter:
        pnt1.x:= (ClientWidth - NSizeArrow div 4) div 2;
    end;

    pnt1.y:= ClientHeight div 2 +
      IfThen(IsPressed, Theme^.PressedCaptionShiftY);

    PaintArrow(pnt1.x, pnt1.y);
  end;

  if FTextOverlay<>'' then
  begin
    TextSize:= Canvas.TextExtent(FTextOverlay);
    Canvas.Brush.Color:= Theme^.ColorBgOverlay;
    Canvas.Font.Color:= Theme^.ColorFontOverlay;

    case Theme^.TextOverlayPosition of
      bopLeftTop:
        begin
          pnt1.x:= 0;
          pnt1.y:= 0;
        end;
      bopRightTop:
        begin
          pnt1.x:= Width-TextSize.cx;
          pnt1.y:= 0;
        end;
      bopLeftBottom:
        begin
          pnt1.x:= 0;
          pnt1.y:= Height-TextSize.cy;
        end;
      bopRightBottom:
        begin
          pnt1.x:= Width-TextSize.cx;
          pnt1.y:= Height-TextSize.cy;
        end;
    end;

    Canvas.TextOut(pnt1.x, pnt1.y, FTextOverlay);
  end;
end;

procedure TATButton.PaintIcon(AX, AY: integer);
begin
  if Assigned(FImages) and (FImageIndex>=0) and (FImageIndex<FImages.Count) then
    FImages.Draw(Canvas, AX, AY, FImageIndex)
  else
  if Assigned(FPicture) then
    Canvas.Draw(AX, AY, FPicture.Graphic);
end;

procedure TATButton.PaintArrow(AX, AY: integer);
var
  NSize: integer;
begin
  NSize:= DoScale(Theme^.ArrowSize);
  CanvasPaintTriangleDown(Canvas, Theme^.ColorArrows,
    Point(AX, AY), NSize);
end;

procedure TATButton.SetBoldFont(AValue: boolean);
begin
  if FBoldFont=AValue then Exit;
  FBoldFont:= AValue;
  AutoSize:= AutoSize;
  Invalidate;
end;

function TATButton.GetIconWidth: integer;
begin
  if Assigned(FImages) then
    Result:= FImages.Width
  else
  if Assigned(FPicture) then
    Result:= FPicture.Width
  else
    Result:= 0;
end;

function TATButton.GetIconHeight: integer;
begin
  if Assigned(FImages) then
    Result:= FImages.Height
  else
  if Assigned(FPicture) then
    Result:= FPicture.Height
  else
    Result:= 0;
end;

procedure TATButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  bOver: boolean;
begin
  inherited;

  bOver:= PtInRect(ClientRect, Point(X, Y));
  if bOver<>FOver then
  begin
    FOver:= bOver;
    Invalidate;
  end;
end;

procedure TATButton.MouseLeave;
begin
  inherited;
  FTimerMouseover.Enabled:= false;
  FOver:= false;
  Invalidate;
end;

procedure TATButton.MouseEnter;
begin
  inherited;
  FOver:= true;
  Invalidate;
  FTimerMouseover.Enabled:= true;
end;

procedure TATButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if Shift=[ssLeft] then
  begin
    FPressed:= true;
    if FFocusable then
      SetFocus;
  end;

  Invalidate;
end;

procedure TATButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  FPressed:= false;
  Invalidate;
end;


procedure TATButton.KeyPress(var Key: char);
begin
  inherited;
  if (Key=' ') then
    Click;
end;

procedure TATButton.DoEnter;
begin
  inherited;
  Invalidate;
end;

procedure TATButton.DoExit;
begin
  inherited;
  Invalidate;
end;

procedure TATButton.TextChanged;
begin
  inherited;
  Invalidate; //paint caption
end;

procedure TATButton.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TATButton.SetAutoSize(AValue: boolean);
var
  NText, NIcon, NGap: integer;
begin
  inherited;
  if not AValue then exit;

  Canvas.Font.Name:= Theme^.FontName;
  Canvas.Font.Size:= DoScaleFont(Theme^.FontSize);
  Canvas.Font.Style:= [];

  //if FBoldFont then
  //  Canvas.Font.Style:= [fsBold]
  //else
  //  Canvas.Font.Style:= [];

  NText:= Canvas.TextWidth(Caption);
  NIcon:= GetIconWidth;
  NGap:= Theme^.GapForAutoSize;

  case FKind of
    abuTextOnly:
      Width:= NText+NGap;
    abuIconOnly:
      Width:= NIcon+NGap;
    abuTextIconHorz:
      Width:= NText+NGap+NIcon+NGap;
    abuTextIconVert:
      Width:= Max(NIcon, NText)+NGap;
  end;
end;

constructor TATButton.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle:= ControlStyle
    +[csOpaque]
    -[csDoubleClicks, csTripleClicks];

  TabStop:= true;
  Width:= 100;
  Height:= 25;

  Caption:= 'Button';
  FPicture:= TPicture.Create;
  FPressed:= false;
  FOver:= false;
  FChecked:= false;
  FCheckable:= false;
  FFocusable:= true;
  FFlat:= false;
  FImages:= nil;
  FImageIndex:= -1;
  FKind:= abuTextOnly;
  FBoldBorder:= false;
  FArrow:= false;
  FArrowAlign:= taRightJustify;
  FPadding:= cDefaultButtonPadding;
  FPaddingBig:= cDefaultButtonPaddingBig;
  FItems:= TStringList.Create;
  FItemIndex:= -1;
  FTheme:= @ATFlatTheme;
  FWidthInitial:= 0;

  FTimerMouseover:= TFPTimer.Create(Self);
  FTimerMouseover.Enabled:= false;
  FTimerMouseover.Interval:= 1000;
  FTimerMouseover.OnTimer:= @TimerMouseoverTick;
end;

destructor TATButton.Destroy;
begin
  FItems.Free;
  FPicture.Free;

  inherited;
end;

function TATButton.GetTextSize(C: TCanvas; const S: string): TSize;
begin
  Result.cx:= 0;
  Result.cy:= 0;
  if S='' then exit;

  if BoldFont then
    C.Font.Style:= [fsBold]
  else
    C.Font.Style:= Theme^.FontStyles;

  Result:= C.TextExtent(S);
end;

procedure TATButton.DoChoiceClick(Sender: TObject);
begin
  FItemIndex:= (Sender as TComponent).Tag;
  Invalidate;
  inherited Click;
end;

procedure TATButton.ShowChoiceMenu;
var
  mi: TMenuItem;
  i: integer;
  P: TPoint;
begin
  if not Assigned(FPopup) then
    FPopup:= TPopupMenu.Create(Self);

  FPopup.Items.Clear;
  for i:= 0 to FItems.Count-1 do
  begin
    mi:= TMenuItem.Create(Self);
    mi.Caption:= FItems[i];
    mi.Tag:= i;
    mi.RadioItem:= true;
    mi.Checked:= i=FItemIndex;
    mi.OnClick:= @DoChoiceClick;
    FPopup.Items.Add(mi);
  end;

  P:= ClientToScreen(Point(0, Height));
  FPopup.PopUp(P.X, P.Y);
end;

procedure TATButton.TimerMouseoverTick(Sender: TObject);
//timer is workaround for LCL issue, where MouseLeave not called
//if mouse leaves app window area (at least on Linux)
var
  Pnt: TPoint;
begin
  Pnt:= ScreenToClient(Mouse.CursorPos);
  if not PtInRect(ClientRect, Pnt) then
    MouseLeave;
end;

function TATButton.DoScale(AValue: integer): integer; inline;
begin
  Result:= Theme^.DoScale(AValue);
end;

function TATButton.DoScaleFont(AValue: integer): integer; inline;
begin
  Result:= Theme^.DoScaleFont(AValue);
end;

end.

