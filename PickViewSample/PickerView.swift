//
//  PickerView.swift
//  PickViewSample
//
//  Created by Emiaostein on 6/3/16.
//  Copyright © 2016 Emiaostein. All rights reserved.
//

import UIKit

// TODO: base horizontal pickerView expend to horizontal & vertical pickerView -- EMIAOSTEIN, 3/06/16, 23:37
private let pickerViewCompnentCellIdentifier = "PickerViewComponentCell"
private let PickerViewRowCellIdentifier = "PickerViewRowCell"
final class PickerView: UIView {
    
    weak var dataSource: PickerViewDataSource?
    weak var delegate: PickerViewDelegate?
    var didSelectedHandler: ((_ component: Int, _ row: Int) -> ())?
    fileprivate var scrollDirection: UICollectionViewScrollDirection = .horizontal
    fileprivate var collectionView: UICollectionView!
    fileprivate var componentIndexCache = PickerViewIndexCache()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let layout = PickerViewLayout()
        layout.scrollDirection = .horizontal
        let c = UICollectionView(frame: bounds, collectionViewLayout: layout)
        c.decelerationRate = UIScrollViewDecelerationRateFast
        c.showsVerticalScrollIndicator = false
        c.showsHorizontalScrollIndicator = false
        c.backgroundColor = UIColor.clear
        c.autoresizingMask = [
            .flexibleLeftMargin,
            .flexibleRightMargin,
            .flexibleTopMargin,
            .flexibleBottomMargin]
        c.register(PickerViewComponentCell.self, forCellWithReuseIdentifier: pickerViewCompnentCellIdentifier)
        c.delegate = self
        c.dataSource = self
        addSubview(c)
        collectionView = c
    }
}

// MARK: - Public Methods
extension PickerView {
    // began from component & index
    func beganFrom(component comp: Int, row: Int) {
        componentIndexCache.changeAt(component: comp, row: row)
        if let attribute = collectionView.layoutAttributesForItem(at: IndexPath(item: comp, section: 0)) {
            let center = attribute.center
            collectionView.setContentOffset(CGPoint(x: center.x - collectionView.bounds.width / 2, y: 0), animated: false)
        }
    }
}

// MARK: - CollectionViewDataSource
extension PickerView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.collectionView {
            return dataSource?.numberOfComponentsInPickerView(pickerView: self) ?? 0
            
        } else if
            let dataSource = dataSource,
            let componentCell = collectionView.superview?.superview as?PickerViewComponentCell,
            let component = self.collectionView.indexPath(for: componentCell)?.item  {
                return dataSource.pickerView(pickerView: self, numberOfRowsInComponent:component)
            
        } else {
            return 100
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.collectionView {
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pickerViewCompnentCellIdentifier, for: indexPath as IndexPath) as? PickerViewComponentCell {
                
                if componentIndexCache.indexAt(component: indexPath.item) == nil {
                    componentIndexCache.changeAt(component: indexPath.item, row: 0)
                }
                
                if cell.collectionView.dataSource == nil {
                    cell.collectionView.dataSource = self
                }
                
                if cell.collectionView.delegate == nil {
                    cell.collectionView.delegate = self
                }
                
                if cell.selector == nil {
                    cell.selector = {[weak self] (comp, row, reusedView, actived, componentActived, rowActived) in
                        guard let sf = self else {return}
                        sf.dataSource?.pickerView(pickerView: sf, viewForRow: row, forComponent: comp, reusingView: reusedView, actived: actived, componentActived: componentActived, rowActived: rowActived)
                        if actived {
                            sf.delegate?.pickerView(pickerView: sf, didSelectRow: row, inComponent: comp)
                        }
                    }
                }
                return cell
                
            } else {
                fatalError()
            }
        } else if
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PickerViewRowCellIdentifier, for: indexPath as IndexPath) as? PickerViewRowCell,
            let componentCell = collectionView.superview?.superview as? PickerViewComponentCell {
            if let component = self.collectionView.indexPath(for: componentCell)?.item {
                let row = indexPath.item
                let ca = componentCell.actived
                let ra = cell.actived
                let actived = componentCell.actived && cell.actived
                if let v = cell.contentView.viewWithTag(1000) {
                        if cell.selector == nil {
                            cell.selector = {[weak self] (comp, row, reusedView, actived, componentActived, rowActived) in
                                guard let sf = self else {return}
                                let _ = sf.dataSource?.pickerView(pickerView: sf, viewForRow: row, forComponent: comp, reusingView: reusedView, actived: actived, componentActived: componentActived, rowActived: rowActived)
                                if actived {
                                    sf.delegate?.pickerView(pickerView: sf, didSelectRow: row, inComponent: comp)
                                }
                            }
                            let _ = dataSource?.pickerView(pickerView: self, viewForRow: row, forComponent: component, reusingView: v, actived: actived, componentActived: ca, rowActived: ra)
                        }

                } else if let v = dataSource?.pickerView(pickerView: self, viewForRow: indexPath.item, forComponent: component, reusingView: nil, actived: actived, componentActived: ca, rowActived: ra) {
                        cell.contentView.addSubview(v)
                        v.translatesAutoresizingMaskIntoConstraints = false
                    if #available(iOS 9.0, *) {
                        v.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
                    } else {
                        // Fallback on earlier versions
                        if #available(iOS 8.0, *) {
                            NSLayoutConstraint(item: v, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
                        } else {
                            // Fallback on earlier versions
                            let top = NSLayoutConstraint(item: v, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0)
                            cell.contentView.addConstraint(top)
                        }
                    }
                    if #available(iOS 9.0, *) {
                        v.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
                    } else {
                        // Fallback on earlier versions
                        if #available(iOS 8.0, *) {
                            NSLayoutConstraint(item: v, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
                        } else {
                            // Fallback on earlier versions
                            let bottom = NSLayoutConstraint(item: v, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
                            cell.contentView.addConstraint(bottom)
                        }
                    }
                    if #available(iOS 9.0, *) {
                        v.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor).isActive = true
                    } else {
                        // Fallback on earlier versions
                        if #available(iOS 8.0, *) {
                            NSLayoutConstraint(item: v, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
                        } else {
                            // Fallback on earlier versions
                            let left = NSLayoutConstraint(item: v, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 0)
                            cell.contentView.addConstraint(left)
                        }
                    }
                    if #available(iOS 9.0, *) {
                        v.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor).isActive = true
                    } else {
                        // Fallback on earlier versions
                        if #available(iOS 8.0, *) {
                            NSLayoutConstraint(item: v, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
                        } else {
                            // Fallback on earlier versions
                            let right = NSLayoutConstraint(item: v, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: 0)
                            cell.contentView.addConstraint(right)
                        }
                    }
                        v.tag = 1000
                }
            }
            
            return cell
            
        } else {
            fatalError()
        }
    }
}

// MARK: - CollectionViewDelegate
extension PickerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? PickerViewComponentCell, let c = cell.collectionView { // row collectionView
            let component = indexPath.item
            
            DispatchQueue.main.async {
//                let i = self.componentIndexCache.indexAt(component: component) ?? 0
//                let attributes = c.layoutAttributesForItem(at: IndexPath(item: i, section: 0))
//                if let attribute = attributes {
//                    let center = attribute.center
                    c.setContentOffset(CGPoint(x: 0, y: -c.bounds.height / 4), animated: false)
//                } 
            }
            
        } else if let _ = cell as? PickerViewRowCell {
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? PickerViewComponentCell, let c = cell.collectionView {
            let point = CGPoint(x: c.bounds.width / 2.0, y: c.contentOffset.y + bounds.height / 2.0)
            if let i = c.indexPathForItem(at: point)?.item {
                let component = indexPath.item
                componentIndexCache.changeAt(component: component, row: i)
            }
            
        } else if let _ = cell as? PickerViewRowCell {
            
        }
    }
}

// MARK: ---------- PickerView DataSource ----------
protocol PickerViewDataSource: NSObjectProtocol {
    
    // Identifier
    // Register Vertical Cell Subclass
    // Horizontal Count
    // Vertical Count at Horizontal Index
    // Vertical Index at horizontal Index
    // Vertical Cell at (Horizontal Index & Vertical Index)
    func numberOfComponentsInPickerView(pickerView: PickerView) -> Int
    func pickerView(pickerView: PickerView, numberOfRowsInComponent component: Int) -> Int
    func pickerView(pickerView: PickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?, actived: Bool, componentActived: Bool, rowActived: Bool) -> UIView
}

// MARK: ---------- PickerView Delegate ----------
protocol PickerViewDelegate: NSObjectProtocol {
    // Vertical Index at Horizontal Index Did Changed to Index
    // Horizontal Index Did Changed to Index
//    func pickerView(pickerView: PickerView, rowHeightForComponent component: Int) -> CGFloat
//    func pickerView(pickerView: PickerView, widthForComponent component: Int) -> CGFloat
    func pickerView(pickerView: PickerView, didSelectRow row: Int, inComponent component: Int)
    
}

// MARK: ---------- PickerViewIndexCache ----------
final class PickerViewIndexCache {
    private var indexs = [Int: Int]()
    private let lock = NSLock()
    
    func changeAt(component com: Int, row: Int?) {
        lock.lock()
        indexs[com] = row
        lock.unlock()
    }
    func indexAt(component com: Int) -> Int? {
        lock.lock()
        let i = indexs[com]
        lock.unlock()
        return i
    }
}

// MARK: ---------- PickerView Vertical & Horzital Layout ----------
final class PickerViewAttributes: UICollectionViewLayoutAttributes {
    
    var actived: Bool = false
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PickerViewAttributes else {
            return false
        }
        return super.isEqual(object) && actived == object.actived
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! PickerViewAttributes
        copy.actived = actived
        return copy
    }
}
final class PickerViewLayout: UICollectionViewFlowLayout {
    
    private var currentIndexPath: NSIndexPath?
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else {return}
        switch scrollDirection {
        case .horizontal:
            let item = CGFloat(2 * 2)
            let r = (1 - 1 / item) / 2
            let width = collectionView.bounds.width
            let height = collectionView.bounds.height
            minimumLineSpacing = 0
            minimumInteritemSpacing = 0
            itemSize = CGSize(width: width / item, height: height)
            
            collectionView.contentInset = UIEdgeInsets(top: 0, left: width * r, bottom: 0, right: width * r)
            
        case .vertical:
            let item = CGFloat(2 * 1)
            let r = (1 - 1 / item) / 2
            let width = collectionView.bounds.width
            let height = collectionView.bounds.height
            itemSize = CGSize(width: width, height: height / item)
            minimumLineSpacing = 0
            minimumInteritemSpacing = 0
            collectionView.contentInset = UIEdgeInsets(top: height * r, left: 0, bottom: height * r, right: 0)
        }
    }
    
    // attributes
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
//    
//    class func layoutAttributesClass() -> AnyClass {
//        return PickerViewAttributes.self
//    }

    
   override class var layoutAttributesClass: AnyClass {
        return PickerViewAttributes.self
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let collectionView = collectionView, let attributes = super.layoutAttributesForElements(in: rect) as? [PickerViewAttributes] else { return nil }
        
        switch scrollDirection {
        case .horizontal:
            
            let visualRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let activeDistance: CGFloat = itemSize.width / 2.0
            
            for attribute in attributes {
                if attribute.frame.intersects(rect) {
                    let distance = fabs((attribute.center.x - visualRect.midX))
                    if distance < activeDistance {
                        if let c = currentIndexPath as? IndexPath, c != attribute.indexPath {
                            if currentIndexPath != nil {
                                
                            }
                            currentIndexPath = attribute.indexPath as NSIndexPath?
                        }
                        attribute.actived = true
                    } else {
                        attribute.actived = false
                    }
                }
            }
            
        case .vertical:
            
            let visualRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let activeDistance: CGFloat = itemSize.height / 2.0
            
            for attribute in attributes {
                if attribute.frame.intersects(rect) {
                    let distance = fabs((attribute.center.y - visualRect.midY))
                    if distance < activeDistance {
                        if  let c = currentIndexPath as? IndexPath, c != attribute.indexPath  {
                            if currentIndexPath != nil {
                                
                            }
                            currentIndexPath = attribute.indexPath as NSIndexPath?
                        }
                        attribute.actived = true
                    } else {
                        attribute.actived = false
                    }
                }
            }
        }
        return attributes
    }
    
//    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//       return super.layoutAttributesForItem(at: indexPath)
//    }
    
    // target scroll
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {return proposedContentOffset}
        
        switch scrollDirection {
        case .horizontal:
            var adjustOffset = CGFloat.greatestFiniteMagnitude
            let proposedContentCenter = CGPoint(
                x: proposedContentOffset.x + collectionView.bounds.width / 2.0,
                y: proposedContentOffset.y + collectionView.bounds.height / 2.0)
            let targetRect = CGRect(origin: proposedContentOffset, size: collectionView.bounds.size)
            
            guard let attributes = layoutAttributesForElements(in: targetRect) else {
                return proposedContentOffset
            }
            
            if fabs(velocity.x) == 0 {
                let centerXs = attributes.map{$0.center.x}.sorted(by: >)
                for x in centerXs {
                    let adjust = x - proposedContentCenter.x
                    if fabs(adjust) < fabs(adjustOffset) {
                        adjustOffset = adjust
                    }
                }
            } else {
                
                if velocity.x < 0 {
                    let centerXs = attributes.map{$0.center.x}.filter{$0 - proposedContentCenter.x < 0}.sorted(by: >)
                    adjustOffset = 0
                    for x in centerXs {
                        let adjust = x - proposedContentCenter.x
                        if adjust < adjustOffset {
                            adjustOffset = adjust
                            break
                        }
                    }
                } else {
                    let centerXs = attributes.map{$0.center.x}.filter{$0 - proposedContentCenter.x > 0}.sorted(by: <)
                    adjustOffset = 0
                    for x in centerXs {
                        let adjust = x - proposedContentCenter.x
                        if adjust > adjustOffset {
                            adjustOffset = adjust
                            break
                        }
                    }
                }
            }
            
            let offset = adjustOffset < 0 ? adjustOffset : adjustOffset
            let point = CGPoint(x: proposedContentOffset.x + offset, y: proposedContentOffset.y)
            return point
            
        case .vertical:
            var adjustOffset = CGFloat.greatestFiniteMagnitude
            let visualCenter = CGPoint(
                x: proposedContentOffset.x + collectionView.bounds.width / 2.0,
                y: proposedContentOffset.y + collectionView.bounds.height / 2.0)
            let targetRect = CGRect(origin: proposedContentOffset, size: collectionView.bounds.size)
            
            guard let attributes = layoutAttributesForElements(in: targetRect) else {
                return proposedContentOffset
            }
            
            let centerYs = attributes.map{$0.center.y}
            if fabs(velocity.y) == 0 {
                for y in centerYs {
                    let adjust = y - visualCenter.y
                    if fabs(adjust) < fabs(adjustOffset) {
                        adjustOffset = adjust
                    }
                }
            } else {
                if velocity.y < 0 {
                    adjustOffset = 0
                    for y in centerYs {
                        let adjust = y - visualCenter.y
                        if adjust < adjustOffset {
                            adjustOffset = adjust
                        }
                    }
                } else {
                    adjustOffset = 0
                    for y in centerYs {
                        let adjust = y - visualCenter.y
                        if adjust > adjustOffset {
                            adjustOffset = adjust
                        }
                    }
                }
            }
            return CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y + adjustOffset)
        }
    }
}

// MARK: ---------- PickerView Cell ----------
class PickerViewCell: UICollectionViewCell {
    
}

// MARK: ---------- PickerView Component Cell ----------
final class PickerViewComponentCell: PickerViewCell {
    
    fileprivate(set) var selector:((Int, Int, UIView?, Bool, Bool, Bool) -> ())?
    fileprivate(set) var actived: Bool = false
    fileprivate(set) var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let layout = PickerViewLayout()
        layout.scrollDirection = .vertical
        let c = UICollectionView(frame: bounds, collectionViewLayout: layout)
        c.decelerationRate = UIScrollViewDecelerationRateFast
        c.backgroundColor = UIColor.clear
        c.showsVerticalScrollIndicator = false
        c.showsHorizontalScrollIndicator = false
        c.register(PickerViewRowCell.self, forCellWithReuseIdentifier: PickerViewRowCellIdentifier)
        c.autoresizingMask = [
            .flexibleLeftMargin,
            .flexibleRightMargin,
            .flexibleTopMargin,
            .flexibleBottomMargin]
        contentView.addSubview(c)
        collectionView = c
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let layoutAttributes = layoutAttributes as? PickerViewAttributes else {return}
        
        if actived != layoutAttributes.actived {
            actived = layoutAttributes.actived
            let component = layoutAttributes.indexPath.item
            let visualRowCells = collectionView.visibleCells
            for c in visualRowCells {
                if let c = c as? PickerViewRowCell, let indexPath = collectionView.indexPath(for: c) {
                    let row = indexPath.item
                    let reusedView = c.contentView.viewWithTag(1000)
                    let active = actived && c.actived
                    selector?(component, row, reusedView, active, c.actived, actived)
                }
            }
        }
    }
}

// MARK: ---------- PickerView Row Cell ----------
final class PickerViewRowCell: PickerViewCell {
    
    var selector:((Int, Int, UIView?, Bool, Bool, Bool) -> ())?
    private(set) var actived: Bool = false
    private weak var superComponentCollectionView: UICollectionView?
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let layoutAttributes = layoutAttributes as? PickerViewAttributes else {return}
        
        if actived != layoutAttributes.actived {
            actived = layoutAttributes.actived
            if let c = superview?.superview?.superview as? PickerViewComponentCell, let coll = superview?.superview?.superview?.superview as? UICollectionView {
                let componentActived = c.actived
                if let component = coll.indexPath(for: c) {
                let v = contentView.viewWithTag(1000)
                selector?(component.item, layoutAttributes.indexPath.item, v, componentActived && actived, componentActived, actived)
                }
            }
        }
    }
}
