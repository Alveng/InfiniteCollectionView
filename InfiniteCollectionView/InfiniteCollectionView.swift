//
//  InfiniteCollectionView.swift
//  Pods
//
//  Created by hryk224 on 2015/10/17.
//
//

import UIKit

public protocol InfiniteCollectionViewDataSource: class {
    func cellForItemAtIndexPath(_ collectionView: InfiniteCollectionView, dequeueIndexPath: IndexPath, indexPath: IndexPath) -> UICollectionViewCell
    func numberOfItems(_ collectionView: InfiniteCollectionView) -> Int
}

@objc public protocol InfiniteCollectionViewDelegate: class {
    @objc optional func didSelectCellAtIndexPath(_ collectionView: InfiniteCollectionView, dequeueIndexPath: IndexPath, indexPath: IndexPath)
    @objc optional func didChangePageIndex(_ collectionView: InfiniteCollectionView, pageIndex: Int)
    @objc optional func collectionViewDidScroll(_ collectionView: InfiniteCollectionView, pageIndex: Int)
}

public enum AutoScrollDirection {
    case right
    case left
}

open class InfiniteCollectionView: UICollectionView {
    fileprivate typealias Me = InfiniteCollectionView
    fileprivate static let dummyCount: Int = 3
    fileprivate static let defaultIdentifier = "Cell"
    
    // MARK: Auto Slide
    fileprivate var autoSlideInterval: TimeInterval = -1
    fileprivate var autoSlideIntervalBackupForLaterUse: TimeInterval = -1
    fileprivate var autoSlideTimer: Timer?
    open var autoSlideDirection: AutoScrollDirection = .right
    
    open weak var infiniteDataSource: InfiniteCollectionViewDataSource?
    open weak var infiniteDelegate: InfiniteCollectionViewDelegate?
    
    open var cellWidth: CGFloat = UIScreen.main.bounds.width
    fileprivate var indexOffset: Int = 0
    open var currentIndex: Int = 0
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        configure()
    }
    
    open func scrollToNext() {
        
        arrangePosition(self)
        self.setContentOffset(CGPoint(x: self.contentOffset.x + cellWidth, y: contentOffset.y), animated: true)
    }
    
    open func scrollToPrev() {
        
        arrangePosition(self)
        self.setContentOffset(CGPoint(x: self.contentOffset.x - cellWidth, y: contentOffset.y), animated: true)
    }
    
    open func updateInfiniteCollectionView() {
        centerIfNeeded(self)
    }
    
}
// MARK: - Public APIs: Auto Slide
extension InfiniteCollectionView {
    /// zero or minus interval disables auto slide.
    public func startAutoSlideForTimeInterval(_ interval: TimeInterval) {
        guard isPlayAutoSlide() == false && interval > 0 else {
            return
        }
        
        stopAutoSlide()
        centerIfNeeded(self)
        autoSlideInterval = interval
        autoSlideTimer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(InfiniteCollectionView.autoSlideCallback(_:)),
            userInfo: nil,
            repeats: true)
        
    }
    
    public func pauseAutoSlide() {
        guard isPlayAutoSlide() == true else {
            return
        }
        
        if autoSlideInterval > 0 {
            autoSlideIntervalBackupForLaterUse = autoSlideInterval
        }
        autoSlideInterval = -1
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
        arrangePosition(self)
    }
    
    public func resumeAutoSlide() {
        guard isPlayAutoSlide() == false else {
            return
        }
        
        if autoSlideIntervalBackupForLaterUse > 0 {
            startAutoSlideForTimeInterval(autoSlideIntervalBackupForLaterUse)
        }
    }
    
    public func stopAutoSlide() {
        autoSlideInterval = -1
        autoSlideIntervalBackupForLaterUse = -1
        autoSlideTimer?.invalidate()
        autoSlideTimer = nil
    }
    
    public func autoSlideCallback(_ timer: Timer) {
        DispatchQueue.main.async {
            if self.autoSlideDirection == .right {
                self.scrollToNext()
            } else {
                self.scrollToPrev()
            }
        }
    }
    
    public func isPlayAutoSlide() -> Bool {
        guard let _ = autoSlideTimer, autoSlideInterval > 0 else {
            return false
        }
        return true
    }
}

// MARK: - private
private extension InfiniteCollectionView {
    func configure() {
        delegate = self
        dataSource = self
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: Me.defaultIdentifier)
    }
    
    func arrangePosition(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x.truncatingRemainder(dividingBy: cellWidth)
        scrollView.contentOffset.x = scrollView.contentOffset.x  - offset
    }
    
    func centerIfNeeded(_ scrollView: UIScrollView) {
        let currentOffset = contentOffset
        let contentWidth = totalContentWidth()
        // Calculate the centre of content X position offset and the current distance from that centre point
        let centerOffsetX: CGFloat = (CGFloat(Me.dummyCount) * contentWidth - bounds.size.width) / 2
        let distFromCentre = centerOffsetX - currentOffset.x
        if fabs(distFromCentre) > (contentWidth / 4) {
            // Total cells (including partial cells) from centre
            let cellcount = distFromCentre / cellWidth
            // Amount of cells to shift (whole number) - conditional statement due to nature of +ve or -ve cellcount
            let shiftCells = Int((cellcount > 0) ? floor(cellcount) : ceil(cellcount))
            // Amount left over to correct for
            let offsetCorrection = (abs(cellcount).truncatingRemainder(dividingBy: 1)) * cellWidth
            // Scroll back to the centre of the view, offset by the correction to ensure it's not noticable
            var isRightScrolling = true
            if centerOffsetX > contentOffset.x {
                //left scrolling
                isRightScrolling = false
                contentOffset = CGPoint(x: centerOffsetX - offsetCorrection, y: currentOffset.y)
            } else if contentOffset.x > centerOffsetX {
                //right scrolling
                isRightScrolling = true
                contentOffset = CGPoint(x: centerOffsetX + offsetCorrection, y: currentOffset.y)
            }
            // Make content shift as per shiftCells
            shiftContentArray(correctedIndex(shiftCells))
            
            let numberOfItems = infiniteDataSource?.numberOfItems(self) ?? 0
            if numberOfItems > 3 {
                reloadData()
            } else if numberOfItems == 2 && isRightScrolling == true {
                reloadData()

            }
        }
        
        let centerPoint = CGPoint(x: scrollView.frame.size.width / 2 + scrollView.contentOffset.x, y: scrollView.frame.size.height / 2 + scrollView.contentOffset.y)
        
        guard let indexPath = indexPathForItem(at: centerPoint) else {
            return
        }
        currentIndex = correctedIndex(indexPath.item - indexOffset)
        infiniteDelegate?.collectionViewDidScroll?(self, pageIndex:currentIndex)
        
    }
    func shiftContentArray(_ offset: Int) {
        indexOffset += offset
    }
    
    func totalContentWidth() -> CGFloat {
        let numberOfCells = infiniteDataSource?.numberOfItems(self) ?? 0
        return CGFloat(numberOfCells) * cellWidth
    }
    
    func correctedIndex(_ indexToCorrect: Int) -> Int {
        if let numberOfItems = infiniteDataSource?.numberOfItems(self), numberOfItems > 0 {
            if numberOfItems > indexToCorrect && indexToCorrect >= 0 {
                return indexToCorrect
            } else {
                let countInIndex = Float(indexToCorrect) / Float(numberOfItems)
                let flooredValue = Int(floor(countInIndex))
                let offset = numberOfItems * flooredValue
                return indexToCorrect - offset
            }
        } else {
            return 0
        }
    }
    
}

// MARK: - UICollectionViewDataSource
extension InfiniteCollectionView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let numberOfItems = infiniteDataSource?.numberOfItems(self) else {
            return 0
        }
        
        if numberOfItems == 1 {
            return 1
        }
        
        return Me.dummyCount * numberOfItems
        
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var maybeCell: UICollectionViewCell!
        maybeCell = infiniteDataSource?.cellForItemAtIndexPath(self, dequeueIndexPath: indexPath, indexPath: IndexPath(row: correctedIndex(indexPath.item - indexOffset), section: 0))
        if maybeCell == nil {
            maybeCell = collectionView.dequeueReusableCell(withReuseIdentifier: Me.defaultIdentifier, for: indexPath)
        }
        return maybeCell
    }
}

// MARK: - UICollectionViewDelegate
extension InfiniteCollectionView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pauseAutoSlide()
        infiniteDelegate?.didSelectCellAtIndexPath?(self, dequeueIndexPath: indexPath, indexPath: IndexPath(row: correctedIndex(indexPath.item - indexOffset), section: 0))
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        DispatchQueue.main.async {
            self.centerIfNeeded(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resumeAutoSlide()
        infiniteDelegate?.didChangePageIndex?(self, pageIndex:self.currentIndex)
        
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            resumeAutoSlide()
            infiniteDelegate?.didChangePageIndex?(self, pageIndex:self.currentIndex)
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseAutoSlide()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        resumeAutoSlide()
        infiniteDelegate?.didChangePageIndex?(self, pageIndex:self.currentIndex)
    }
}

