//
//  DVPositionManager.swift
//  BottomDrawerProject
//
//  Created by Lorenzo Toscani De Col on 15/03/2019.
//  Copyright © 2019 Lorenzo Toscani De Col. All rights reserved.
//

import UIKit

protocol DVPositionManagerDelegate: AnyObject {
	func updateDrawerFrame(byAmount amount: CGFloat)
	func updateDrawerPosition(_ position: DVPosition)
}

class DVPositionManager {
	
	weak var delegate: DVPositionManagerDelegate?
	
	/**
	A CGFloat value that indicates draggable view height, so that it clears the bottom of the view.
	*/
	private var dragViewOffset: CGFloat
	
	var maxMovement: CGFloat {
		let maxHeight = frame(forPosition: supportedPositions.max() ?? DVPosition.defaultExpanded).height
		let minHeight = frame(forPosition: supportedPositions.min() ?? DVPosition.defaultCollapsed).height
		return abs(maxHeight -  minHeight)
	}
	
	var supportedPositions: Set<DVPosition> = [DVPosition.defaultExpanded, DVPosition.defaultPartial, DVPosition.defaultCollapsed]
	var minPosition: DVPosition {
		supportedPositions.min() ?? DVPosition.defaultCollapsed
	}
	var maxPosition: DVPosition {
		supportedPositions.max() ?? DVPosition.defaultExpanded
	}
	
	private var screenHeight: CGFloat { UIScreen.main.bounds.height }
	private var screenWidth: CGFloat { UIScreen.main.bounds.width }
	/**
	A CGFloat value indicating the height of the view.
	*/
	var totalHeight: CGFloat {
		let maxExpanded = supportedPositions.max() ?? DVPosition.defaultExpanded
		return screenHeight * maxExpanded.percent
	}
	
	var currentPosition: DVPosition = DVPosition.defaultExpanded
	
	var tapToExpand: Bool = false
	
	init(interactiveViewHeight: CGFloat) {
		dragViewOffset = interactiveViewHeight
	}
	
	/**
	Calculates the frame of the view in a certain position.
	
	- Parameter position: The position of the frame you want to get.
	- Returns: A CGRect indicating the frame of the view in that position.
	*/
	func frame(forPosition position: DVPosition) -> CGRect {
		CGRect(origin: CGPoint(x: 0, y: referencePointY(forPosition: position)),
				 size: CGSize(width: screenWidth, height: totalHeight))
	}
	
	func referencePointY(forPosition position: DVPosition) -> CGFloat {
		return screenHeight - (screenHeight * position.percent)
	}
	
	static func height(for position: DVPosition) -> CGFloat {
		return UIScreen.main.bounds.height * position.percent
	}
	
	/**
	Calculates the closest Position to a certain point.
	
	- Parameter point: The point from which you want to find the position.
	- Returns: The **Position** closest to the point.
	*/
	func closestPosition(fromPoint point: CGPoint) -> DVPosition {
		var closest: DVPosition?
		supportedPositions.forEach {
			if let currentClosest = closest {
				let current = abs(point.y - referencePointY(forPosition: currentClosest))
				let new = abs(point.y - referencePointY(forPosition: $0))
				if new < current {
					closest = $0
				}
			} else {
				closest = $0
			}
		}
		return closest ?? DVPosition.defaultExpanded
	}
	
	func nextPosition() -> DVPosition {
		let sortedPositions = supportedPositions.sorted()
		if let currentIndex = sortedPositions.firstIndex(of: currentPosition) {
			let next = currentIndex.advanced(by: 1)
			if next < sortedPositions.count {
				return sortedPositions[next]
			}
		}
		return currentPosition
	}
	
	func previousPosition() -> DVPosition {
		let sortedPositions = supportedPositions.sorted()
		if let currentIndex = sortedPositions.firstIndex(of: currentPosition) {
			let previous = currentIndex.advanced(by: -1)
			if previous >= 0 {
				return sortedPositions[previous]
			}
		}
		return currentPosition
	}
}

extension DVPositionManager: DVHeaderViewDelegate {
	func didTapOnHeader(_ gesture: UITapGestureRecognizer) {
		guard tapToExpand,
				currentPosition == supportedPositions.min(),
				let max = supportedPositions.max(),
				max != currentPosition else
		{
				return
		}
		delegate?.updateDrawerPosition(max)
	}
	
	func didPan(_ gesture: UIPanGestureRecognizer) {
		guard let gestureView = gesture.view, let drawer = gestureView.superview else { return }
		switch gesture.state {
		case .began, .changed:
			let translationAmount = gesture.translation(in: drawer).y
			gesture.setTranslation(.zero, in: drawer)
			delegate?.updateDrawerFrame(byAmount: translationAmount)
		case .ended, .cancelled:
			let velocity = gesture.velocity(in: drawer).y
			let velocityThreshold: CGFloat = 2000
			let slowVelocityThreshold: CGFloat = 400
			
			var updatedPosition = currentPosition
			if velocity > velocityThreshold {
				updatedPosition = supportedPositions.min() ?? DVPosition.defaultCollapsed
			} else if velocity < -velocityThreshold {
				updatedPosition = supportedPositions.max() ?? DVPosition.defaultExpanded
			} else {
				let closest = closestPosition(fromPoint: drawer.frame.origin)
				if velocity > slowVelocityThreshold {
					let previous = previousPosition()
					updatedPosition = closest < previous ? closest : previous
				} else if velocity < -slowVelocityThreshold {
					let next = nextPosition()
					updatedPosition = closest > next ? closest : next
				} else {
					updatedPosition = closest
				}
			}
			gesture.setTranslation(.zero, in: gestureView.superview ?? gestureView)
			delegate?.updateDrawerPosition(updatedPosition)
		default:
			print(gesture.state.self)
		}
	}
}
