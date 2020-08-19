//
//  ViewController.swift
//  Pixaby
//
//  Created by Shivam Sharma on 19/08/20.
//  Copyright © 2020 Shivam Sharma. All rights reserved.
//

import CHTCollectionViewWaterfallLayout
import Alamofire
import SDWebImage
import CoreData
import SVProgressHUD

class HomeVC: UIViewController {
    
    @IBOutlet weak var viewHeadSearch: UIView!
    
    @IBOutlet weak var txtFieldSearch: UITextField!
    
    @IBOutlet weak var colViewImages: UICollectionView!{
        didSet{
            let layout = CHTCollectionViewWaterfallLayout()
            
            layout.minimumColumnSpacing = 1.0
            layout.minimumInteritemSpacing = 1.0
            
            // Collection view attributes
            colViewImages.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            colViewImages.alwaysBounceVertical = true
            colViewImages.collectionViewLayout = layout
            colViewImages.register(UINib(nibName: "ImageCVC", bundle: nil), forCellWithReuseIdentifier: "ImageCVC")
            colViewImages.dataSource = self
            colViewImages.delegate = self
            
        }
    }
    var imageData: [Hits]?
    var pageNumber = 1
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.viewHeadSearch.addGradientWith(direction: .vertical, and: Constants.Colors.AppGradColorFirst.value,Constants.Colors.AppGradColorSecond.value)
        
    }
    
    //    MARK:- Network Call
    
    private func callApi(with text:String,pageNumber:Int){
        SVProgressHUD.show()
  AF.request("\(Constants.Defaults.BASE_URL)key=\(Constants.Defaults.pixApiKey)&q=\(text)&image_type=photo&page=\(pageNumber)&per_page=20",method: .get).responseJSON { (response) in
            guard response.error == nil else {
                // got an error in getting the data, need to handle it
                print(response.error!)
                return
            }
            
            // make sure we got some JSON since that's what we expect
            guard let json = response.value as? [String: Any] else {
                if let error = response.error {
                    print("Error: \(error)")
                }
                return
            }
            if let data = json["hits"] as? [Any]{
                if pageNumber>1{
                    let tempArr = Hits.modelsFromDictionaryArray(array: data as NSArray)
                    for hits in tempArr{
                        self.imageData?.append(hits)
                    }
                    
//                    self.imageData?.append(Hits.modelsFromDictionaryArray(array: data as NSArray))
                }else{
                    self.imageData = Hits.modelsFromDictionaryArray(array: data as NSArray)

                }
                self.colViewImages.reloadData()
                DispatchQueue.main.async {

                SVProgressHUD.dismiss()
                }
                let context = self.appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Suggestions", in: context)
                let newSearchWord = NSManagedObject(entity: entity!, insertInto: context)
                newSearchWord.setValue("\(text)", forKey: "suggestSearch")
                do {
                    try context.save()
                } catch {
                    print("Failed saving")
                }
            }
            
        }
    }
    
}
extension HomeVC:UICollectionViewDelegate,UICollectionViewDataSource,CHTCollectionViewDelegateWaterfallLayout{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageData?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCVC", for: indexPath) as! ImageCVC
        
        cell.imgViewPicture.sd_setImage(with: URL(string: self.imageData?[indexPath.row].previewURL ?? ""), completed: nil)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if imageData!.count > 0{
            
            let imgWidth = Float(imageData![indexPath.row].previewWidth!)
            let imgHeight = Float(imageData![indexPath.row].previewHeight!)
            
            let aspectRatio = CGFloat(imgHeight/imgWidth)
            
            return CGSize(width: CGFloat(collectionView.frame.size.width/2), height: CGFloat(CGFloat(collectionView.frame.size.width/2) * aspectRatio))
            
        }
        return CGSize(width: 0,height: 0)
    }
    
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

                   print("scrollViewDidEndDragging")
                   if ((colViewImages.contentOffset.y + colViewImages.frame.size.height ) >= colViewImages.contentSize.height - 50)
       {
                    pageNumber += 1
                    callApi(with: txtFieldSearch.text!, pageNumber:pageNumber)
                    colViewImages.reloadData()
                   }
    }
    
    
}

extension HomeVC:UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !(textField.text!.isEmpty){
            callApi(with: textField.text!,pageNumber: 1)
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField.text?.count ?? 0 > 2{
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Suggestions")
            request.returnsObjectsAsFaults = false
            do {
                let context = self.appDelegate.persistentContainer.viewContext
                
                let result = try context.fetch(request)
                if result.count>0{
                    for data in result as! [NSManagedObject] {
                        print(data.value(forKey: "suggestSearch") as! String)
                    }
                }
            } catch {
                print("Failed")
            }
        }
    return true
    }
}
