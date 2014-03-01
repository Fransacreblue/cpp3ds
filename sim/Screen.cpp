#include <SFML/Graphics.hpp>
#include <sim3ds/sim/Simulator.h>
#include <cpp3ds/Screen.h>
#include <cpp3ds/Color.h>
#include <cpp3ds/Drawable.h>
#include <cpp3ds/utils.h>
#include <string.h>

namespace cpp3ds {

	void Screen::setPixel(int x, int y, Color color){
		sf::Color c(color.r, color.g, color.b);
		pixelImage.setPixel(x, y, c);
	}

	void Screen::clear(Color color){
		sf::RectangleShape box(sf::Vector2f(width, height));
		sf::Color c(color.r, color.g, color.b);
		box.setFillColor(c);
		box.setPosition(x,y);
		// Should only clear the relevant screen area
		_simulator->screen->renderWindow.draw(box);
	}

	void Screen::draw(Drawable& obj, float x, float y, bool use3D) {
		// TODO: Check bounds and don't draw objects outside screen
		obj.draw(*this, x, y, use3D, true);
	}

	void Screen::display() {
		sf::Texture starsTexture;
        starsTexture.loadFromImage(pixelImage);
        sf::Sprite test(starsTexture);
        test.setPosition(x, y);

        _simulator->screen->renderWindow.draw(test);
		_simulator->screen->display();
	}

}
