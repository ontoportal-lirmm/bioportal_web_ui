import {Controller} from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ['pageItem','pageContent' ,'backBtn', 'nextBtn', 'finishBtn']
    connect() {
        this.pagesItems = this.pageItemTargets
        this.buttons = [this.backBtnTarget, this.nextBtnTarget, this.finishBtnTarget]
        this.currentForm = 1
    }

    navigateBack(){
        this.navigateForm('back')
    }
    navigateNext(){
        this.navigateForm('next')
    }

    navigateForm(direction) {
        if (direction === "next"  && this.currentForm < this.pagesItems.length) {
            this.currentForm += 1
            this.showForm()
        } else if (direction === "back" && this.currentForm > 1){
            this.currentForm -= 1
            this.showForm()
        }
    }

    showForm(){
        const targetForm = this.currentForm
        for (let index = 1; index <= this.pagesItems.length; index++) {

            const targetFormDOM = this.pageContentTargets[index - 1];

            const isCurrentForm = targetForm === index;

            targetFormDOM.classList.toggle("hide", !isCurrentForm);

            if (isCurrentForm) {
                this.updateProgressBar(targetForm);
                this.updateButtons(targetForm);
            }

        }

    }
    updateProgressBar(targetForm) {
        const progressItemsDOM = document.querySelectorAll(".progress-item > div");
        const line = document.querySelectorAll(".line");

        progressItemsDOM.forEach((item, index) => {
            const isPassedSection = index + 1 < targetForm;
            const isCurrentSection = index + 1 === targetForm;

            item.children[0].classList.toggle("outlined-checked-circle", isPassedSection);
            item.children[0].classList.toggle("outlined-active-circle", isCurrentSection);


            item.children[1].classList.toggle("active", isCurrentSection || isPassedSection);


            line[index]?.classList.toggle("active", isPassedSection);
        });
    }

    updateButtons(targetForm) {

        switch (targetForm) {
            case 1:
                this.showBtn([this.buttons[1]]);
                break;
            case this.pagesItems.length:
                this.showBtn([this.buttons[0], this.buttons[2]]);
                break;
            default:
                this.showBtn([this.buttons[0], this.buttons[1]]);
        }

    }

    showBtn(btnIds = []) {
        this.buttons.forEach((btn) => {
            const targetBtnDOM = btn;
            const shouldShowBtn = btnIds.includes(btn);
            targetBtnDOM.classList.toggle("hide", !shouldShowBtn);
        });
    }
}
