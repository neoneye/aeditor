#include "fx.h"
#include "fxkeys.h"

#include <algorithm> 
using std::min;
using std::max;

#include <iostream>
using std::cout; 
using std::endl;

enum {
	EDITOR_NORMAL = FRAME_THICK|FRAME_SUNKEN
};

typedef FXint EditorBackground;

class Cell {
public:
	int glyph;
	EditorBackground background;

	Cell() : glyph(0), background(0) {}
};

class Editor : public FXScrollArea {
	FXDECLARE(Editor)
public:
	Editor(
		FXComposite* p,
		FXObject* target=NULL,
		FXSelector sel=0,
		FXuint opts=EDITOR_NORMAL,
		FXint x=0,
		FXint y=0,
		FXint width=0,
		FXint height=0);
	virtual ~Editor();
	virtual void create();
	long onPaint(FXObject *, FXSelector, void *);
	long onConfigure(FXObject *, FXSelector, void *);
	long onKeyPress(FXObject *, FXSelector, void *);
	long onFocusIn(FXObject *, FXSelector, void *);
	long onFocusOut(FXObject *, FXSelector, void *);
	long onLeftButtonPress(FXObject *, FXSelector, void *); 

	virtual FXint getDefaultWidth() const;
	virtual FXint getDefaultHeight() const;

	virtual FXbool canFocus() const;
private:
	Editor() {}
	Editor(const Editor &) {}
	void randomize_cells();

	void render(
		FXDCWindow& dc, 
		FXint x, 
		FXint y, 
		FXint width, 
		FXint height) const;
	void render_row_background(
		FXDCWindow& dc,
		FXint line_number,
		FXint x_begin,
		FXint x_end) const;
	void render_row_text(
		FXDCWindow& dc,
		FXint line_number,
		FXint x_begin,
		FXint x_end) const;
	void render_multicell_background(
		FXDCWindow& dc,
		FXint line_number,
		FXint x_begin,
		FXint n,
		EditorBackground background) const;
	void render_cell_glyph(
		FXDCWindow& dc,
		FXint line_number,
		FXint x_begin,
		Cell &cell) const;
	void render_cursor(
		FXDCWindow& dc) const;
	void render_cursor1(
		FXDCWindow& dc) const;

	Cell *cells;
	// size of the array of cells
	FXint cells_height;
	FXint cells_width;

	FXFont *font;
	// size of a single cell
	FXint cell_height;
	FXint cell_width;

	// cursor position
	FXint cursor_x;
	FXint cursor_line;
};

FXDEFMAP(Editor) EditorMap[] = {
	FXMAPFUNC(SEL_PAINT, 0, Editor::onPaint),
	FXMAPFUNC(SEL_CONFIGURE, 0, Editor::onConfigure),
	FXMAPFUNC(SEL_KEYPRESS, 0, Editor::onKeyPress),
	FXMAPFUNC(SEL_FOCUSIN, 0, Editor::onFocusIn),
	FXMAPFUNC(SEL_FOCUSOUT, 0, Editor::onFocusOut),  
	FXMAPFUNC(SEL_LEFTBUTTONPRESS,0, Editor::onLeftButtonPress),
};

FXIMPLEMENT(
	Editor,
	FXScrollArea,
	EditorMap,
	ARRAYNUMBER(EditorMap))

/* ------------------------------------

   Create/Destroy widget

------------------------------------ */
Editor::Editor(
	FXComposite* p,
	FXObject* target,
	FXSelector sel,
	FXuint options,
	FXint x,
	FXint y,
	FXint width,
	FXint height) :
	FXScrollArea(p, options, x, y, width, height) {

	/* 
	I wonder exactly what FLAG_ENABLED's purpose are.
	It seems to control if a widget can recieve 
	focus or not. todo: figure out its purpose.
	*/
	flags|=FLAG_ENABLED;


	// cursor position
	cursor_x = 1;
	cursor_line = 1;

	// setup font
	font = new FXFont(getApp(),"helvetica",20);
	cell_height = 10;
	cell_width = 10;

	// array of cells
	cells_width = 10;
	cells_height = 10;
	cells = new Cell[cells_width * cells_height]; 
	randomize_cells();
}

void Editor::randomize_cells() {
	FXint i;
	for(i=0; i<cells_width*cells_height; i++) {
		cells[i].glyph = i;
		cells[i].background = rand();
	}
}

Editor::~Editor() {
	delete [] cells;
	delete font;
}

void Editor::create() {
	FXScrollArea::create();
	font->create();
	cell_height = font->getFontHeight();
	cell_width = font->getFontWidth();
}

/* ------------------------------------

   Resize / Size of widget

------------------------------------ */
long Editor::onConfigure(
	FXObject *sender, 
	FXSelector sel, 
	void *ptr) {
	FXint w, h;
	w = getWidth();
	h = getHeight();
	cout << "resize: " << w << "x" << h << endl;

	cells_width = (w + cell_width - 1) / cell_width;
	cells_height = (h + cell_height - 1) / cell_height;
	delete [] cells;
	cells = new Cell[cells_width * cells_height]; 
	randomize_cells();
	return 1;
}

FXint Editor::getDefaultWidth() const {
	return 100;
}

FXint Editor::getDefaultHeight() const {
	return 100;
}


/* ------------------------------------

   Repaint content of widget

------------------------------------ */
long Editor::onPaint(
	FXObject *sender, 
	FXSelector, 
	void *ptr) {
	FXEvent *event = static_cast<FXEvent*>(ptr);
	FXDCWindow dc(this, event);
	dc.setTextFont(font);
	FXRectangle &r = event->rect;
	render(dc, r.x, r.y, r.w, r.h);  
	return 1;
}
void Editor::render(
	FXDCWindow& dc, 
	FXint x, 
	FXint y, 
	FXint width, 
	FXint height) const {
	// y
	FXint y_begin = max(y / cell_height, 0); 
	FXint yt = y + height + cell_height - 1;
	FXint y_end = min(yt / cell_height, cells_height-1);

	// x
	FXint x_begin = max(x / cell_width, 0);
	FXint xt = x + width + cell_width - 1;
	FXint x_end = min(xt / cell_width, cells_width-1);

	cout << "render: " << 
		"y=[" << y_begin << ".." << y_end << 
		"], x=[" << x_begin << ".." << x_end << "]" << endl;

	FXint i;
	for(i=y_begin; i <= y_end; i++) {
		render_row_background(dc, i, x_begin, x_end);
	}

	render_cursor(dc);

	for(i=y_begin; i <= y_end; i++) {
		render_row_text(dc, i, x_begin, x_end);
	}
}

void Editor::render_row_background(
	FXDCWindow& dc,
	FXint line_number,
	FXint x_begin,
	FXint x_end) const {
	FXint x;
	Cell *line = &cells[line_number*cells_width];

	// clear background (find biggest span)
	EditorBackground background = line[x_begin].background;
	FXint n = 0;
	for(x=x_begin; x<=x_end; x++) {
		EditorBackground new_background = line[x].background;
		if(new_background != background) {
			render_multicell_background(
				dc, line_number, x - n, n, background);
			background = new_background;
			n = 1;
		}
		n++;
	}
	render_multicell_background(
		dc, line_number, x - n, n, background);
}

void Editor::render_row_text(
	FXDCWindow& dc,
	FXint line_number,
	FXint x_begin,
	FXint x_end) const {
	FXint x;
	Cell *line = &cells[line_number*cells_width];

	// draw glyphs
	for(x=x_begin; x<=x_end; x++) {  
		render_cell_glyph(dc, line_number, x, line[x]);
	}
}

void Editor::render_multicell_background(
	FXDCWindow& dc,
	FXint line_number,
	FXint x_begin,
	FXint n,
	EditorBackground background) const {
	FXColor color=0;

	// todo: make a more advanced color selection system
	if(background & 1)
		color = FXRGB(140,40,40);
	else
		color = FXRGB(80,127,180);

	FXint x = x_begin * cell_width;
	FXint w = n * cell_width;
	FXint y = line_number * cell_height;
	dc.setForeground(color);
	dc.fillRectangle(x,y,w,cell_height);
}

void Editor::render_cell_glyph(
	FXDCWindow& dc,
	FXint line_number,
	FXint x_begin,
	Cell &cell) const {

	FXColor color=FXRGB(0, 0, 0);
	char s[2];
	s[1] = 0;
	s[0] = cell.glyph; // todo: do unicode rendering!
	FXString text = s;

	FXint x = x_begin * cell_width;
	x += (cell_width - 
		font->getTextWidth(text.text(), text.length())) / 2;
	FXint y = line_number * cell_height;
	y += font->getFontAscent();
	dc.setForeground(color);
	dc.drawText(x, y, text.text(), text.length());
}

void Editor::render_cursor(
	FXDCWindow& dc) const {

	FXint x = cursor_x * cell_width;
	FXint y = cursor_line * cell_height;
	dc.setForeground(FXRGB(40, 200, 40));
	dc.fillRectangle(x, y, cell_width, cell_height);
}

void Editor::render_cursor1(
	FXDCWindow& dc) const {

	FXint x = cursor_x * cell_width - 1;
	FXint w = 5;
	FXint y = cursor_line * cell_height;
	FXint x2 = x - 2;
	FXint w2 = w + 4;

	FXColor color1=FXRGB(40, 200, 40);
	FXColor color2=FXRGB(0, 160, 0);

	dc.setForeground(color2);
	dc.fillRectangle(x2, y-1, w2, 2);
	dc.fillRectangle(x2, y+cell_height-1, w2, 2);

	dc.setForeground(color1);
	dc.fillRectangle(x, y, w, cell_height);
}

/* ------------------------------------

   Process incoming events

------------------------------------ */
FXbool Editor::canFocus() const {
	return true;
}

long Editor::onFocusIn(
	FXObject *sender, 
	FXSelector sel, 
	void *ptr) {
	FXScrollArea::onFocusIn(sender, sel, ptr);
	cout << "got focus" << endl;
	return 1;
}

long Editor::onFocusOut(
	FXObject *sender, 
	FXSelector sel, 
	void *ptr) {
	FXScrollArea::onFocusOut(sender, sel, ptr);
	cout << "lost focus" << endl;
	return 1;
}

long Editor::onLeftButtonPress(
	FXObject *sender, 
	FXSelector sel, 
	void *ptr) {
	handle(this, MKUINT(0, SEL_FOCUS_SELF), ptr);
	FXEvent *event = static_cast<FXEvent*>(ptr);
	if(!isEnabled()) {
		cout << "leftclick (bailout)" << endl;
		return 0;
	}
	if(event->click_count==1) {
		FXint x = event->win_x;
		FXint y = event->win_y;
		cout << "leftclick x=" << x << " y=" << y << endl;
		cursor_x = (x + (cell_width/5)) / cell_width;
		cursor_line = y / cell_height;
		update();
	}
	return 1;
}

long Editor::onKeyPress(
	FXObject *sender, 
	FXSelector sel, 
	void *ptr) {
	FXEvent *event = static_cast<FXEvent*>(ptr);
	switch(event->code) {
	case KEY_Up:
	case KEY_KP_Up: 
		cout << "keypress (key_up)" << endl;
		cursor_line--;
		update();
		break;
	case KEY_Down:
	case KEY_KP_Down: 
		cout << "keypress (key_down)" << endl;
		cursor_line++;
		update();
		break;
	case KEY_Left:
	case KEY_KP_Left: 
		cout << "keypress (key_left)" << endl;
		cursor_x--;
		update();
		break;
	case KEY_Right:
	case KEY_KP_Right: 
		cout << "keypress (key_right)" << endl;
		cursor_x++;
		update();
		break;
	default:
		cout << "keypress (unhandled)"
			"keysym=" << getClassName() <<
			", code=" << event->code <<
			", state=" << event->state << endl;
		return 0;
	}
	return 1;
}

class MainWindow : public FXMainWindow {
	FXDECLARE(MainWindow)
public:
	MainWindow(FXApp* a);
	virtual ~MainWindow();
	virtual void create();

	enum {
		ID_PANEL=FXMainWindow::ID_LAST,
		ID_EDITOR,
	};

private:
	MainWindow() {}

	FXMenubar*         menubar;
	FXMenuPane*        filemenu;
	FXHorizontalFrame* contents;
	FXTabBook*         tabbook;
	FXTabItem*         tab1;
	FXHorizontalFrame* listframe;
	Editor*            editor;
};

FXDEFMAP(MainWindow) MainWindowMap[] = {
};

FXIMPLEMENT(
	MainWindow,
	FXMainWindow,
	MainWindowMap,
	ARRAYNUMBER(MainWindowMap))

MainWindow::MainWindow(FXApp *a) : 
	FXMainWindow(a,"Test Custom Widget",NULL,NULL,DECOR_ALL,0,0,600,400) {

	new FXTooltip(getApp());

	menubar=new FXMenubar(this,LAYOUT_SIDE_TOP|LAYOUT_FILL_X);
	new FXHorizontalSeparator(this,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE);
	contents=new FXHorizontalFrame(this,LAYOUT_SIDE_TOP|FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH);
	tabbook=new FXTabBook(contents,this,ID_PANEL,LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT);

	tab1=new FXTabItem(tabbook,"Buffer #1",NULL);
	listframe=new FXHorizontalFrame(tabbook,FRAME_THICK|FRAME_RAISED);
	editor = new Editor(listframe, this, ID_EDITOR, LAYOUT_FILL_X|LAYOUT_FILL_Y);

	filemenu=new FXMenuPane(this);
	new FXMenuCommand(filemenu,"&Quit\tCtl-Q",NULL,getApp(),FXApp::ID_QUIT);
	new FXMenuTitle(menubar,"&File",NULL,filemenu);
}

MainWindow::~MainWindow() {
	delete filemenu;
}

void MainWindow::create() {
	FXMainWindow::create();
	show(PLACEMENT_SCREEN);
}

int main(int argc, char *argv[]) {
	FXApp application("Main", "Test Custom Widget");
	application.init(argc,argv);
	new MainWindow(&application);
	application.create();
	return application.run();
}
