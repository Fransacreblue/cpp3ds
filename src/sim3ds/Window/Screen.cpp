#include <string.h>
#include <cpp3ds/Simulator/Simulator.hpp>
#include <cpp3ds/Graphics/Color.hpp>
#include <cpp3ds/Graphics/Drawable.hpp>
#include <cpp3ds/System/utils.hpp>
#include <cpp3ds/Window/Screen.hpp>

namespace cpp3ds {

	void Screen::setPixel(int x, int y, Color color){
		sf::Color c(color.r, color.g, color.b);
		pixelImage.setPixel(x, y, c);
	}

	void Screen::clear(Color color){
		sf::RectangleShape box(sf::Vector2f(width, height));
		sf::Color c(color.r, color.g, color.b);
		sf::Color outline(25,25,25);
		box.setFillColor(c);
		box.setOutlineColor(outline);
		box.setOutlineThickness(SIM_OUTLINE_THICKNESS);
		box.setPosition(x,y);
		pixelImage.create(width, height, sf::Color::Transparent);
		// Should only clear the relevant screen area
		_simulator->screen->draw(box);
	}

	void Screen::draw(Drawable& obj, float x, float y, bool use3D) {
		// TODO: Check bounds and don't draw objects outside screen
		obj.draw(*this, x, y, use3D, true);
	}

	void Screen::_display() {
		sf::Texture starsTexture;
		starsTexture.loadFromImage(pixelImage);
		sf::Sprite test(starsTexture);
		test.setPosition(x, y);
		_simulator->screen->draw(test);
	}

}
