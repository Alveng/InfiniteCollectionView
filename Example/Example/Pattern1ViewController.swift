//
//  Pattern1ViewController.swift
//  Example
//
//  Created by hiroyuki yoshida on 2016/01/04.
//  Copyright © 2016年 hiroyuki yoshida. All rights reserved.
//

import UIKit
import InfiniteCollectionView

final class Pattern1ViewController: UIViewController {
    var items = ["1", "2", "3", "4"]
    @IBOutlet weak var collectionView: InfiniteCollectionView! {
        didSet {
            collectionView.infiniteDataSource = self
            collectionView.infiniteDelegate = self
            collectionView.cellWidth = UIScreen.main.bounds.width
            collectionView.register(ImageCollectionViewCell.nib, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        }
    }
    @IBOutlet weak var layout: UICollectionViewFlowLayout! {
        didSet {
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }
    @IBOutlet weak var pageControl: UIPageControl! {
        didSet {
            pageControl.numberOfPages = items.count
        }
    }
    static func createFromStoryboard() -> Pattern1ViewController {
        let storyboard = UIStoryboard(name: "Pattern1", bundle: nil)
        return storyboard.instantiateInitialViewController() as! Pattern1ViewController
    }
}

// MARK: - InfiniteCollectionViewDataSource, InfiniteCollectionViewDelegate
extension Pattern1ViewController: InfiniteCollectionViewDataSource, InfiniteCollectionViewDelegate {
    func numberOfItems(_ collectionView: UICollectionView) -> Int {
        return items.count
    }
    func cellForItemAtIndexPath(_ collectionView: UICollectionView, dequeueIndexPath: IndexPath, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: dequeueIndexPath) as! ImageCollectionViewCell
        cell.configure(dequeueIndexPath: indexPath)
        return cell
    }
    func didSelectCellAtIndexPath(_ collectionView: UICollectionView, indexPath: IndexPath) {
    }
    func didUpdatePageIndex(_ index: Int) {
        pageControl.currentPage = index
    }
}
