//
//  InfiniteCollectionView.swift
//  Pods
//
//  Created by hryk224 on 2015/10/17.
//
//

import UIKit

public protocol InfiniteCollectionViewDataSource: class {
    func cellForItemAtIndexPath(collectionView: UICollectionView, dequeueIndexPath: NSIndexPath, indexPath: NSIndexPath) -> UICollectionViewCell
    func numberOfItems(collectionView: UICollectionView) -> Int
}

@objc public protocol InfiniteCollectionViewDelegate: class {
    optional func didSelectCellAtIndexPath(collectionView: UICollectionView, indexPath: NSIndexPath)
    optional func didChangePageIndex(collectionView: UICollectionView, pageIndex: Int)
    optional func collectionViewDidScroll(collectionView: UICollectionView, pageIndex: Int)
}

public enum AutoScrollDirection {
    case Right
    case Left
}

public class InfiniteCollectionView: UICollectionView {
    private typealias Me = InfiniteCollectionView
    private static let dummyCount: Int = 3
    private static let defaultIdentifier = "Cell"
    
    // MARK: Auto Slide
    private var autoSlideInterval: NSTimeInterval = -1
    private var autoSlideIntervalBackupForLaterUse: NSTimeInterval = -1
    private var autoSlideTimer: NSTimer?
    public var autoSlideDirection: AutoScrollDirection = .Right
    
    public weak var infiniteDataSource: InfiniteCollectionViewDataSource?
    public weak var infiniteDelegate: InfiniteCollectionViewDelegate?
    
    public var cellWidth: CGFloat = UIScreen.mainScreen().bounds.width
    private var indexOffset: Int = 0
    public var currentIndex: Int = 0
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        configure()
    }
    
    public func scrollToNext() {
        
        arrangePosition(self)
        self.setContentOffset(CGPointMake(self.contentOffset.x + cellWidth, contentOffset.y), animated: true)
    }
    
    public func scrollToPrev() {
        
        arrangePosition(self)
        self.setContentOffset(CGPointMake(self.contentOffset.x - cellWidth, contentOffset.y), animated: true)
    }
    
    public func updateInfiniteCollectionView() {
        centerIfNeeded(self)
    }
    
}
// MARK: - Public APIs: Auto Slide
extension InfiniteCollectionView {
    /// zero or minus interval disables auto slide.
    public func startAutoSlideForTimeInterval(interval: NSTimeInterval) {
        guard isPlayAutoSlide() == false && interval > 0 else {
            return
        }
        
        stopAutoSlide()
        centerIfNeeded(self)
        autoSlideInterval = interval
        autoSlideTimer = NSTimer.scheduledTimerWithTimeInterval(
            interval,
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
    
    public func autoSlideCallback(timer: NSTimer) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.autoSlideDirection == .Right {
                self.scrollToNext()
            } else {
                self.scrollToPrev()
            }
        }
    }
    
    public func isPlayAutoSlide() -> Bool {
        guard let _ = autoSlideTimer where autoSlideInterval > 0 else {
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
        registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: Me.defaultIdentifier)
    }
    
    func arrangePosition(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x % cellWidth
        scrollView.contentOffset.x = scrollView.contentOffset.x  - offset
    }
    
    func centerIfNeeded(scrollView: UIScrollView) {
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
            let offsetCorrection = (abs(cellcount) % 1) * cellWidth
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
        
        guard let indexPath = indexPathForItemAtPoint(centerPoint) else {
            return
        }
        currentIndex = correctedIndex(indexPath.item - indexOffset)
        infiniteDelegate?.collectionViewDidScroll?(self, pageIndex:currentIndex)
        
    }
    func shiftContentArray(offset: Int) {
        indexOffset += offset
    }
    
    func totalContentWidth() -> CGFloat {
        let numberOfCells = infiniteDataSource?.numberOfItems(self) ?? 0
        return CGFloat(numberOfCells) * cellWidth
    }
    
    func correctedIndex(indexToCorrect: Int) -> Int {
        if let numberOfItems = infiniteDataSource?.numberOfItems(self) {
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
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let numberOfItems = infiniteDataSource?.numberOfItems(self) else {
            return 0
        }
        
        if numberOfItems == 1 {
            return 1
        }
        
        return Me.dummyCount * numberOfItems
        
    }
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var maybeCell: UICollectionViewCell!
        maybeCell = infiniteDataSource?.cellForItemAtIndexPath(self, dequeueIndexPath: indexPath, indexPath: NSIndexPath(forRow: correctedIndex(indexPath.item - indexOffset), inSection: 0))
        if maybeCell == nil {
            maybeCell = collectionView.dequeueReusableCellWithReuseIdentifier(Me.defaultIdentifier, forIndexPath: indexPath)
        }
        return maybeCell
    }
}

// MARK: - UICollectionViewDelegate
extension InfiniteCollectionView: UICollectionViewDelegate {
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        pauseAutoSlide()
        infiniteDelegate?.didSelectCellAtIndexPath?(self, indexPath: NSIndexPath(forRow: correctedIndex(indexPath.item - indexOffset), inSection: 0))
    }
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        dispatch_async(dispatch_get_main_queue()) {
            self.centerIfNeeded(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        resumeAutoSlide()
        infiniteDelegate?.didChangePageIndex?(self, pageIndex:self.currentIndex)
        
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            resumeAutoSlide()
            infiniteDelegate?.didChangePageIndex?(self, pageIndex:self.currentIndex)
        }
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        pauseAutoSlide()
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        resumeAutoSlide()
        infiniteDelegate?.didChangePageIndex?(self, pageIndex:self.currentIndex)
    }
}

