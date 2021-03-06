#ifdef Q_WS_X11
    #include <Qt/qx11info_x11.h>
    #include <X11/Xlib.h>
#endif
#include <iostream>
#include <cpp3ds/Emulator/SFMLWidget.hpp>
#include <cpp3ds/Graphics/Color.hpp>

QSFMLCanvas::QSFMLCanvas(QWidget* Parent) :
QWidget       (Parent),
myInitialized (false),
paintCount (0)
{
    // Setup some states to allow direct rendering into the widget
    setAttribute(Qt::WA_PaintOnScreen);
    setAttribute(Qt::WA_OpaquePaintEvent);
    setAttribute(Qt::WA_NoSystemBackground);
    setAttribute(Qt::WA_PaintUnclipped);

	topLeftScreen.create(400, 240, true);
	topRightScreen.create(400, 240, true);
	bottomScreen.create(320, 240, true);

    // Set strong focus to enable keyboard events to be received
    setFocusPolicy(Qt::WheelFocus);

    QSizePolicy test = this->sizePolicy();// (QSizePolicy::Minimum, QSizePolicy::Minimum);
    test.setHeightForWidth(true);
    setSizePolicy(test);
    std::cout << "QSFMLCanvas Made!" << std::endl;
}

QSFMLCanvas::~QSFMLCanvas(){}

void QSFMLCanvas::showEvent(QShowEvent*)
{
    if (!myInitialized) {
        // Under X11, we need to flush the commands sent to the server to ensure that
        // SFML will get an updated view of the windows
        #ifdef Q_WS_X11
            XFlush(QX11Info::display());
        #endif

        // Create the SFML window with the widget handle
		RenderWindow::create(winId());

        myInitialized = true;
    }
}

void QSFMLCanvas::resizeEvent (QResizeEvent* event) {
	RenderWindow::onResize();
	int w = event->size().width(),
	    h = event->size().height();
	std::cout << "RESIZED width:" << w << " height:" << h << std::endl;
}

int QSFMLCanvas::heightForWidth( int w ) {
	std::cout << "test" << std::endl;
	return w;
}

QPaintEngine* QSFMLCanvas::paintEngine() const {
//	We make the paintEvent function return a null paint engine. This functions works together with
//	the WA_PaintOnScreen flag to tell Qt that we're not using any of its built-in paint engines.
	return nullptr;
}

void QSFMLCanvas::paintEvent(QPaintEvent*) {
	// Dirty hack to get cleared black widget after initialization
	if (paintCount++ < 2) {
		std::cout << "QSFMLCanvas::paintEvent" << std::endl;
		RenderWindow::clear(sf::Color::Black);
		RenderWindow::display();
	}
}

void QSFMLCanvas::mousePressEvent(QMouseEvent* event) {
    sf::Event e;
    e.type = sf::Event::MouseButtonPressed;
    e.mouseButton.x = event->x();
    e.mouseButton.y = event->y();
    pushMouseEvent(e);
}
void QSFMLCanvas::mouseMoveEvent(QMouseEvent* event) {
	sf::Event e;
	e.type = sf::Event::MouseMoved;
	e.mouseButton.x = event->x();
	e.mouseButton.y = event->y();
	pushMouseEvent(e);
}
void QSFMLCanvas::mouseReleaseEvent(QMouseEvent* event) {
	sf::Event e;
	e.type = sf::Event::MouseButtonReleased;
	e.mouseButton.x = event->x();
	e.mouseButton.y = event->y();
	pushMouseEvent(e);
}

void QSFMLCanvas::pushMouseEvent(const sf::Event& event) {
	m_events.push(event);
}

bool QSFMLCanvas::pollMouseEvent(sf::Event& event) {
	// Pop the first event of the queue, if it is not empty
	if (!m_events.empty()) {
		event = m_events.front();
		m_events.pop();
		return true;
	}
	return false;
}
